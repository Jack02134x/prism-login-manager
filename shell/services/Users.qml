pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// People who can log in: regular accounts (UID_MIN..UID_MAX, a real shell),
// minus plm.json's users.hidden. Avatars are looked up in order: PLM's synced
// copy, AccountsService, then ~/.face (only readable when the home allows it);
// the helper checks which one we can actually read.
Singleton {
    id: root

    property var list: []
    property bool loaded: false
    readonly property var names: list.map(u => u.name)

    function find(name) {
        return list.find(u => u.name === name) ?? null;
    }
    function displayName(name) {
        const u = find(name);
        return u ? (u.real || u.name) : String(name ?? "");
    }
    function avatars(name) {
        const a = find(name)?.avatar ?? "";
        return a !== "" ? ["file://" + a] : [];
    }
    function shellOf(name) {
        return find(name)?.shell ?? "/bin/sh";
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }
    // test mode switches to the system's synced data once it knows it exists
    Connections {
        target: Config
        function onSyncRootChanged() {
            root.refresh();
        }
    }

    Process {
        id: proc
        running: true
        command: [Config.helper, "users", Config.syncRoot]
        stdout: StdioCollector {
            onStreamFinished: {
                const hidden = Array.from(Config.users.hidden ?? []);
                root.list = text.split("\n").filter(l => l.length > 0).map(l => {
                    const [name, uid, real, home, shell, avatar, poster] = l.split("\t");
                    return { name, uid: parseInt(uid), real: real ?? "", home: home ?? "", shell: shell ?? "", avatar: avatar ?? "", poster: poster ?? "" };
                }).filter(u => !hidden.includes(u.name));
                root.loaded = true;
            }
        }
    }
}
