pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// What the greeter remembers between boots: the last user, and each user's
// last session. Lives in /var/lib/plm/state.json (owned by the greeter user).
Singleton {
    id: root

    property alias lastUser: adapter.lastUser
    property alias userSessions: adapter.sessions
    property bool loaded: false

    function sessionFor(user) {
        return (adapter.sessions ?? {})[user] ?? "";
    }
    function remember(user, session) {
        if (!Config.remember)
            return;
        const s = Object.assign({}, adapter.sessions ?? {});
        s[user] = session;
        adapter.sessions = s;
        adapter.lastUser = user;
        file.writeAdapter();
    }

    Process {
        running: !Config.greeter
        command: ["mkdir", "-p", Config.stateDir]
    }

    FileView {
        id: file
        path: Config.stateFile
        printErrors: false
        // the greeter quits right after saving: write before launch() returns
        blockWrites: true
        atomicWrites: true
        onLoaded: root.loaded = true
        onLoadFailed: root.loaded = true

        JsonAdapter {
            id: adapter
            property string lastUser: ""
            property var sessions: ({})
        }
    }
}
