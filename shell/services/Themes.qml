pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Finds themes and loads the active one into Theme.
//
// Search order (the first folder with an id wins): your own
// ~/.local/share/plm/themes (test mode and the editor only), /etc/plm/themes
// (installed with `plm theme install`), then the bundled ones.
Singleton {
    id: root

    readonly property var dirs: (Config.greeter ? [] : [Config.userThemeDir]).concat(["/etc/plm/themes", Config.dataDir + "/themes"])
    // [{ id, dir, name, user, system, bundled }]
    property var list: []
    property bool loaded: false
    // a theme id, or a folder path
    property string wanted: Config.themeOverride !== "" ? Config.themeOverride : Config.theme
    readonly property string activeDir: {
        if (wanted.includes("/"))
            return wanted.replace(/\/theme\.json$/, "").replace(/\/$/, "");
        const t = list.find(t => t.id === wanted) ?? list.find(t => t.id === "prism") ?? list[0];
        return t?.dir ?? "";
    }
    property string loadError: ""

    function find(id) {
        return list.find(t => t.id === id) ?? null;
    }
    function isWritable(dir) {
        return dir.startsWith(Config.userThemeDir + "/");
    }

    // re-read the active theme.json (drops unsaved edits)
    function reload() {
        themeFile.reload();
    }
    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    Process {
        id: listProc
        running: Config.loaded
        command: [Config.helper, "themes"].concat(root.dirs)
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(l => l.length > 0).map(l => {
                    const [id, dir, name] = l.split("\t");
                    return {
                        id,
                        dir,
                        name,
                        user: dir.startsWith(Config.userThemeDir + "/"),
                        system: dir.startsWith("/etc/plm/"),
                        bundled: dir.startsWith(Config.dataDir + "/themes/")
                    };
                });
                root.loaded = true;
            }
        }
    }

    // load (and in test mode / the editor, live-reload) the active theme.json
    FileView {
        id: themeFile
        path: root.activeDir !== "" ? root.activeDir + "/theme.json" : ""
        watchChanges: !Config.greeter
        printErrors: false
        onFileChanged: {
            // the editor's own saves don't reload (that would drop undo history)
            if (!root.saving)
                reload();
        }
        onLoaded: {
            try {
                Theme.load(JSON.parse(text()), root.activeDir);
                root.loadError = "";
            } catch (e) {
                root.loadError = "theme.json: " + e;
                console.warn("PLM:", root.loadError);
                if (!Theme.ready)
                    Theme.load({}, root.activeDir);
            }
        }
        onLoadFailed: {
            root.loadError = "Can't read " + path;
            if (!Theme.ready)
                Theme.load({}, Config.dataDir + "/themes");
        }
    }
    // no theme anywhere: still show something
    Timer {
        running: root.loaded && root.activeDir === "" && !Theme.ready
        interval: 10
        onTriggered: Theme.load({}, Config.dataDir + "/themes")
    }

    // ---- editor: saving ------------------------------------------------------
    property bool saving: false
    signal saved(string dir)
    signal saveFailed(string message)

    // write Theme.data into `dir` (copying `from` there first, for "save as")
    function save(dir, from) {
        saving = true;
        saveFile.targetDir = dir;
        saveFile.payload = JSON.stringify(Theme.data, null, 4) + "\n";
        prep.command = ["sh", "-c", "mkdir -p \"$1\" && { [ -z \"$2\" ] || [ \"$2\" = \"$1\" ] || cp -rnT -- \"$2\" \"$1\"; }", "plm", dir, from ?? ""];
        prep.running = true;
    }
    Process {
        id: prep
        onExited: code => {
            if (code !== 0) {
                root.saving = false;
                root.saveFailed("Couldn't create " + saveFile.targetDir);
                return;
            }
            saveFile.path = saveFile.targetDir + "/theme.json";
            saveFile.setText(saveFile.payload);
        }
    }
    FileView {
        id: saveFile
        property string targetDir: ""
        property string payload: ""
        blockWrites: true
        atomicWrites: true
        printErrors: false
        onSaved: {
            Theme.dirty = false;
            root.saved(targetDir);
            root.refresh();
            settle.restart();
        }
        onSaveFailed: err => {
            root.saving = false;
            root.saveFailed("Couldn't write theme.json");
        }
    }
    Timer {
        id: settle
        interval: 400
        onTriggered: root.saving = false
    }
}
