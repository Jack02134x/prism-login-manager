#!/usr/bin/env bash
# Prism Login Manager installer.
#
#   ./install.sh                 ask before each step (Enter takes the default)
#   ./install.sh --yes           take every default (never switches the login screen on by itself)
#   ./install.sh --yes --enable  ...and switch to PLM at the next boot
#   ./install.sh --dry-run       print every command, change nothing
#   ./install.sh --uninstall     take it back out
#
# Other options: --no-packages, --no-setup, --no-sync, --prefix DIR
#
# Works on its own. The Prism shell's installer can run it with --yes too; when
# Prism is installed, PLM also offers to follow its wallpaper and colours.

set -euo pipefail

REPO_URL=${PLM_REPO:-https://github.com/Jack02134x/prism-login-manager}
PREFIX=/usr
YES=0 DRY=0 ENABLE=0 UNINSTALL=0 PACKAGES=1 SETUP=1 SYNC=1

while [ $# -gt 0 ]; do
    case "$1" in
    --yes | -y) YES=1 ;;
    --dry-run) DRY=1 ;;
    --enable) ENABLE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --no-packages) PACKAGES=0 ;;
    --no-setup) SETUP=0 ;;
    --no-sync) SYNC=0 ;;
    --prefix) PREFIX=$2; shift ;;
    -h | --help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

bold=$'\e[1m' dim=$'\e[2m' acc=$'\e[38;5;117m' ok=$'\e[32m' warn=$'\e[33m' off=$'\e[0m'
say() { printf '%s\n' "$*"; }
step() { printf '\n%s◆ %s%s\n' "$acc$bold" "$*" "$off"; }
note() { printf '  %s%s%s\n' "$dim" "$*" "$off"; }
good() { printf '  %s✓%s %s\n' "$ok" "$off" "$*"; }
bad() { printf '  %s!%s %s\n' "$warn" "$off" "$*"; }

# run (or, with --dry-run, just show) a command
run() {
    if [ "$DRY" = 1 ]; then
        printf '  %s$ %s%s\n' "$dim" "$*" "$off"
    else
        "$@"
    fi
}
# yes/no question; $2 is the default (y|n)
ask() {
    local q=$1 def=${2:-y} a
    if [ "$YES" = 1 ]; then [ "$def" = y ]; return; fi
    local hint="[Y/n]"; [ "$def" = n ] && hint="[y/N]"
    read -r -p "  $q $hint " a </dev/tty || a=
    a=${a:-$def}
    [[ "$a" =~ ^[Yy] ]]
}

if [ "$(id -u)" = 0 ]; then
    echo "Run this as your normal user; it uses sudo when it needs to." >&2
    exit 1
fi
SUDO=sudo

# ---- the source: this checkout, or a fresh clone ----
here=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)
if [ -f "$here/shell/shell.qml" ]; then
    SRC=$here
else
    SRC=${XDG_CACHE_HOME:-$HOME/.cache}/plm/src
    step "Downloading PLM"
    if [ -d "$SRC/.git" ]; then run git -C "$SRC" pull --ff-only; else run git clone --depth 1 "$REPO_URL" "$SRC"; fi
fi

printf '\n%s  Prism Login Manager%s\n' "$bold" "$off"
note "a login screen for greetd, built on Quickshell: themes, a theme editor, live wallpapers"
[ "$DRY" = 1 ] && note "dry run: nothing will change"

# ---- uninstall ----
if [ "$UNINSTALL" = 1 ]; then
    step "Removing PLM"
    if systemctl is-enabled greetd.service >/dev/null 2>&1 && grep -qs plm-session /etc/greetd/config.toml; then
        prev=$(cat /etc/plm/.previous-dm 2>/dev/null || true)
        if [ -n "$prev" ]; then
            ask "Switch the login screen back to $prev?" y && { run $SUDO systemctl disable greetd.service; run $SUDO systemctl enable "$prev"; }
        else
            bad "greetd still runs PLM's login screen; it'll be gone at the next boot."
            ask "Turn greetd off (you'll log in on the console)?" y && run $SUDO systemctl disable greetd.service
        fi
        bak=$(ls -t /etc/greetd/config.toml.bak-plm-* 2>/dev/null | head -n 1 || true)
        [ -n "$bak" ] && run $SUDO cp "$bak" /etc/greetd/config.toml && good "restored $bak"
    fi
    systemctl --user disable --now plm-sync.path >/dev/null 2>&1 || true
    run rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/plm-sync."{path,service}
    run $SUDO make -C "$SRC" uninstall PREFIX="$PREFIX"
    if ask "Also delete settings and synced wallpapers (/etc/plm, /var/lib/plm)?" n; then
        run $SUDO rm -rf /etc/plm /var/lib/plm
    fi
    good "PLM removed (packages stay installed)"
    exit 0
fi

# ---- packages ----
if [ "$PACKAGES" = 1 ]; then
    step "Packages"
    if command -v pacman >/dev/null 2>&1; then
        need=(greetd quickshell qt6-multimedia qt6-multimedia-ffmpeg ttf-nerd-fonts-symbols adwaita-fonts ttf-roboto jq python)
        if ! command -v Hyprland >/dev/null 2>&1 && ! command -v sway >/dev/null 2>&1 && ! command -v cage >/dev/null 2>&1; then
            note "the login screen needs a small compositor to run in; cage is the lightest"
            need+=(cage)
        fi
        missing=()
        for p in "${need[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
        extras=()
        for p in ffmpegthumbnailer imagemagick zenity; do pacman -Q "$p" >/dev/null 2>&1 || extras+=("$p"); done
        if [ ${#missing[@]} -gt 0 ]; then
            note "needed: ${missing[*]}"
            if ask "Install them?" y; then run $SUDO pacman -S --needed --noconfirm "${missing[@]}"; else bad "skipped; PLM may not run"; fi
        else
            good "everything needed is installed"
        fi
        if [ ${#extras[@]} -gt 0 ]; then
            note "optional: ${extras[*]} (video thumbnails and poster frames, the editor's file picker)"
            ask "Install those too?" y && run $SUDO pacman -S --needed --noconfirm "${extras[@]}"
        fi
    else
        bad "not an Arch system: install greetd, quickshell (with greetd support), qt6-multimedia + its FFmpeg backend,"
        bad "Symbols Nerd Font, jq and python yourself, plus Hyprland, sway or cage."
    fi
fi

# ---- files ----
step "Installing PLM to $PREFIX"
if [ "$DRY" = 1 ]; then run $SUDO make -C "$SRC" install PREFIX="$PREFIX"; else $SUDO make -C "$SRC" install PREFIX="$PREFIX" >/dev/null; fi
good "plm, plm-session, $PREFIX/share/plm"

# ---- greetd ----
if [ "$SETUP" = 1 ]; then
    step "Login screen"
    dmargs=()
    [ "$DRY" = 1 ] && dmargs+=(--dry-run)
    current=
    if [ -e /etc/systemd/system/display-manager.service ]; then
        current=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")
    fi
    [ -n "$current" ] && [ "$current" != greetd.service ] && note "your login screen now: $current"
    if [ "$ENABLE" = 1 ]; then
        dmargs+=(--enable)
    elif [ "$current" != greetd.service ]; then
        note "Try it first with: plm test   (a window, nothing logs in)"
        ask "Switch to PLM at the next boot?" n && dmargs+=(--enable)
    fi
    run $SUDO "$PREFIX/bin/plm" setup "${dmargs[@]}"
fi

# ---- your desktop at the login screen ----
if [ "$SYNC" = 1 ]; then
    step "Your wallpaper at the login screen"
    prism=${XDG_CONFIG_HOME:-$HOME/.config}/quickshell
    if [ -f "$prism/.state/palette.json" ]; then
        good "found the Prism shell: the Prism theme follows its wallpaper (live ones too), colours and avatar"
        run "$PREFIX/bin/plm" sync || bad "sync failed; run 'plm sync' later"
        if ask "Keep following it whenever the wallpaper changes?" y; then run "$PREFIX/bin/plm" sync --auto; fi
    else
        note "no Prism shell here. Pick a login wallpaper any time:"
        note "  plm sync --wallpaper ~/Pictures/something.jpg   (pictures, GIFs and videos)"
        run "$PREFIX/bin/plm" sync --quiet || true
    fi
fi

step "Done"
say "  ${bold}plm test${off}      try the login screen in a window (any password works there)"
say "  ${bold}plm editor${off}    design your own theme, with a live preview"
say "  ${bold}plm themes${off}    see what's installed;  ${bold}plm doctor${off} checks everything"
