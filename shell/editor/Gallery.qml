pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Wallpapers to pick from in the editor: Prism's wallpaper folders when Prism
// is installed, plus the usual places. Video thumbnails come from Prism's
// cache when it has them, otherwise PLM makes its own (ffmpegthumbnailer).
Singleton {
    id: root

    readonly property string prismDir: Config.home + "/.config/quickshell"
    property var prismConfig: null
    // the same test `plm sync` and install.sh use: Prism has written its palette
    property bool hasPrism: false
    readonly property var dirs: {
        const w = prismConfig?.wallpaper ?? {};
        const d = [w.dir, w.videoDir, Config.home + "/Pictures/Wallpapers", Config.home + "/Videos/Wallpapers", Config.home + "/wallpapers", Config.home + "/Pictures", Config.home + "/Videos"];
        return d.filter((x, i) => x && d.indexOf(x) === i);
    }
    readonly property string thumbDir: Config.home + "/.cache/plm/thumbs"

    // [{ path, kind, thumb }]
    property var items: []
    property bool loaded: false
    property int thumbsVersion: 0

    function thumb(path, kind) {
        if (kind !== "video")
            return "file://" + path;
        const name = Utils.fileName(path) + ".jpg";
        return "file://" + (prismThumbs.includes(name) ? prismDir + "/.cache/vthumbs/" : thumbDir + "/") + name;
    }
    property var prismThumbs: []

    function load() {
        if (!listProc.running)
            listProc.running = true;
    }

    FileView {
        path: root.prismDir + "/.state/palette.json"
        printErrors: false
        onLoaded: root.hasPrism = true
        onLoadFailed: root.hasPrism = false
    }

    FileView {
        path: root.prismDir + "/config.json"
        printErrors: false
        onLoaded: {
            try {
                root.prismConfig = JSON.parse(text());
            } catch (e) {
                root.prismConfig = null;
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c", "ls \"$1\" 2>/dev/null; echo '::'; shift; exec \"$@\"", "plm", root.prismDir + "/.cache/vthumbs", Config.helper, "media"].concat(root.dirs)
        stdout: StdioCollector {
            onStreamFinished: {
                const [thumbs, media] = text.split("::\n");
                root.prismThumbs = (thumbs ?? "").split("\n").filter(l => l.length > 0);
                const seen = {};
                root.items = (media ?? "").split("\n").filter(l => l.length > 0 && !seen[l] && (seen[l] = true)).slice(0, 400).map(p => {
                    const kind = Utils.mediaKind(p);
                    return { path: p, kind, thumb: root.thumb(p, kind) };
                });
                root.loaded = true;
                thumbProc.running = true;
            }
        }
    }

    // thumbnails for videos Prism hasn't thumbnailed (idle priority, skips existing)
    Process {
        id: thumbProc
        command: ["sh", "-c", "command -v ffmpegthumbnailer >/dev/null || exit 0; mkdir -p \"$1\"; d=$1; shift; for f in \"$@\"; do o=\"$d/${f##*/}.jpg\"; [ -s \"$o\" ] || nice -n 15 ffmpegthumbnailer -i \"$f\" -o \"$o\" -s 320 -t 15% >/dev/null 2>&1; done", "plm", root.thumbDir].concat(root.items.filter(i => i.kind === "video" && !root.prismThumbs.includes(Utils.fileName(i.path) + ".jpg")).map(i => i.path))
        onExited: root.thumbsVersion++
    }
}
