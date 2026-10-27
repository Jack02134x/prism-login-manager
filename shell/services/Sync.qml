pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// The selected user's Prism desktop, as copied by `plm sync` into
// <syncRoot>/<user>/prism.json: wallpaper (image, gif or live video), a poster
// frame, and the palette. Absent for people who don't run Prism.
Singleton {
    id: root

    readonly property string dir: Config.syncRoot + "/" + Auth.user
    property var info: null
    readonly property bool available: info !== null && wallpaper !== ""
    readonly property string wallpaper: info?.wallpaper ? fileIn(info.wallpaper) : ""
    readonly property string poster: info?.poster ? fileIn(info.poster) : ""
    readonly property string kind: info?.kind ?? Utils.mediaKind(wallpaper)
    readonly property var palette: info?.palette ?? null
    readonly property var gradient: palette?.gradient ?? []

    function fileIn(name) {
        name = String(name);
        return "file://" + (name.startsWith("/") ? name : dir + "/" + name);
    }

    FileView {
        id: file
        path: Auth.user !== "" ? root.dir + "/prism.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.info = JSON.parse(text());
            } catch (e) {
                root.info = null;
            }
        }
        onLoadFailed: root.info = null
        onPathChanged: root.info = null
    }
}
