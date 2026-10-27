pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Where everything lives, which mode we run in, and the system settings
// (/etc/plm/plm.json). The greeter only reads plm.json; `plm config` writes it.
//
//   PLM_MODE        greeter (default) | test | editor
//   PLM_CONFIG      settings file            (default /etc/plm/plm.json)
//   PLM_STATE_DIR   last user / session      (default /var/lib/plm, test: ~/.cache/plm)
//   PLM_THEME       theme id or directory    (overrides plm.json)
//   PLM_WINDOW      layer | floating         (floating for cage and test windows)
//   PLM_SCREENSHOT  save the screen to this PNG after PLM_SCREENSHOT_DELAY ms, then quit
Singleton {
    id: root

    readonly property string mode: env("PLM_MODE", "greeter")
    readonly property bool greeter: mode === "greeter"
    readonly property bool test: mode === "test"
    readonly property bool editor: mode === "editor"
    // a normal window instead of full-screen layer surfaces
    readonly property bool windowed: editor || env("PLM_WINDOW", greeter ? "layer" : "floating") === "floating"

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string userName: Quickshell.env("USER") ?? ""
    readonly property string shellDir: Quickshell.shellDir
    // /usr/share/plm when installed, the repository when run from source
    readonly property string dataDir: shellDir.replace(/\/shell\/?$/, "")
    readonly property string helper: shellDir + "/scripts/plm-helper"
    readonly property string configFile: env("PLM_CONFIG", "/etc/plm/plm.json")
    readonly property string stateDir: env("PLM_STATE_DIR", greeter ? "/var/lib/plm" : home + "/.cache/plm")
    readonly property string stateFile: stateDir + "/state.json"
    // per-user data written by `plm sync` (wallpaper, palette, avatar). Test mode
    // reads the system copy when there is one, else the user's own cache.
    readonly property string syncDir: env("PLM_SYNC_DIR", "")
    property string syncRoot: syncDir !== "" ? syncDir : (greeter ? "/var/lib/plm/users" : stateDir + "/users")
    readonly property string userThemeDir: home + "/.local/share/plm/themes"
    readonly property string themeOverride: env("PLM_THEME", "")
    readonly property string screenshot: env("PLM_SCREENSHOT", "")
    readonly property int screenshotDelay: parseInt(env("PLM_SCREENSHOT_DELAY", "3500"))

    function env(name, fallback) {
        const v = Quickshell.env(name);
        return v === null || v === undefined || v === "" ? fallback : String(v);
    }

    // test mode: prefer the system's synced data when PLM is installed
    Process {
        running: !root.greeter && root.syncDir === ""
        command: ["test", "-d", "/var/lib/plm/users/" + root.userName]
        onExited: code => {
            if (code === 0)
                root.syncRoot = "/var/lib/plm/users";
        }
    }

    property alias theme: adapter.theme
    property alias monitor: adapter.monitor
    property alias defaultUser: adapter.defaultUser
    property alias defaultSession: adapter.defaultSession
    property alias remember: adapter.remember
    property alias users: adapter.users
    property alias sessions: adapter.sessions
    property alias power: adapter.power
    property alias clock24h: adapter.clock24h
    property alias ambientAfter: adapter.ambientAfter
    property alias prismSync: adapter.prismSync
    property alias sessionEnv: adapter.env

    property bool loaded: false

    FileView {
        path: root.configFile
        watchChanges: !root.greeter
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loaded = true
        onLoadFailed: root.loaded = true

        JsonAdapter {
            id: adapter

            // theme id (a folder in /etc/plm/themes or /usr/share/plm/themes)
            property string theme: "prism"
            // monitor that shows the login box ("" = the first one); click another to move it
            property string monitor: ""
            property string defaultUser: ""
            property string defaultSession: ""
            // pre-select the last user and each user's last session
            property bool remember: true
            property JsonObject users: JsonObject {
                property bool showList: true
                property list<string> hidden: []
                // let people type a user name that isn't listed
                property bool allowOther: true
            }
            property JsonObject sessions: JsonObject {
                property list<string> hidden: []
                // add the user's login shell as a session (runs on the console)
                property bool shell: false
                // extra sessions: [{ "name": "…", "exec": "…", "type": "wayland" }]
                property var extra: []
            }
            property JsonObject power: JsonObject {
                property bool suspend: true
                property bool hibernate: false
                property bool reboot: true
                property bool poweroff: true
            }
            property bool clock24h: true
            // seconds without input before the screen fades to just the clock (0 = never);
            // a theme's effects.ambientAfter wins when it sets one
            property int ambientAfter: 45
            // follow each user's Prism desktop (wallpaper + colours) when the theme asks for it
            property bool prismSync: true
            // extra environment for launched sessions: ["KEY=value", …]
            property list<string> env: []
        }
    }
}
