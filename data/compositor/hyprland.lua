-- PLM: the Hyprland that runs the login screen (as the greeter user).
-- plm-session starts it with `Hyprland -c` this file; nothing here touches your
-- own Hyprland config. Put monitor layouts and other machine-specific settings
-- in /etc/plm/hyprland.lua; it's loaded at the end when it exists.

local share = os.getenv("PLM_SHARE") or "/usr/share/plm"

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")

hl.config({
    input = {
        kb_layout  = os.getenv("PLM_KB_LAYOUT") or "us",
        kb_variant = os.getenv("PLM_KB_VARIANT") or "",
        kb_options = os.getenv("PLM_KB_OPTIONS") or "",
        numlock_by_default = os.getenv("PLM_NUMLOCK") == "1",
        follow_mouse = 1,
        touchpad = {
            tap_to_click = true,
        },
    },

    general = {
        border_size = 0,
        gaps_in     = 0,
        gaps_out    = 0,
    },

    decoration = {
        rounding = 0,
        blur     = { enabled = false },
        shadow   = { enabled = false },
    },

    animations = {
        enabled = false,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
    },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

-- Start the greeter; when it quits (after a login, or if it fails) leave Hyprland
-- so greetd can start the session.
hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'quickshell -p \"" .. share .. "/shell\"; hyprctl dispatch \"hl.dsp.exit()\"'")
end)

local site = io.open("/etc/plm/hyprland.lua", "r")
if site then
    site:close()
    dofile("/etc/plm/hyprland.lua")
end
