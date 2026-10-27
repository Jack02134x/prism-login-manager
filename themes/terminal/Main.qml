// Terminal: a custom PLM layout. A theme with "layout": "custom" loads this
// file and hands it one object, `plm`, with everything a login screen needs:
//
//   plm.auth       user, session, phase (idle|busy|prompt|launching), prompt,
//                  error, info; submit(text), selectUser(name), cycleUser(±1),
//                  selectSession(id), cycleSession(±1), cancel()
//   plm.users      list [{ name, real, uid, avatar }], displayName(name)
//   plm.sessions   list [{ id, name, type, comment }], find(id)
//   plm.power      actions [{ id, label, icon }], run(id), hasBattery, percent
//   plm.keyboard   capsLock, hostname
//   plm.theme      the theme: accent1..3, text, textDim, error, font, mono, data, get(path)
//   plm.activity   poke() (keeps ambient mode away while someone types)
//   plm.view       reveal / ambientT animations;  plm.backdrop  the background item
//   plm.clock, plm.loginBox, plm.userMenu, plm.sessionMenu, plm.powerButtons,
//   plm.statusChips, plm.avatar, plm.inputField, plm.glass, plm.chip ...:
//                  PLM's own building blocks as Components (use them in a Loader)
//
// Only import Qt modules here; PLM's own modules aren't visible to theme files.
// Define `focusField()` and `typing` so PLM can focus the field and blur the
// background while typing.

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var plm
    readonly property var auth: plm.auth
    readonly property var theme: plm.theme
    readonly property bool typing: field.text.length > 0
    // the console scrolls: everything that happened so far
    property var log: []

    function focusField() {
        field.forceActiveFocus();
    }
    function say(line) {
        log = log.concat([line]).slice(-14);
    }

    Component.onCompleted: {
        say("PLM console login on " + (plm.keyboard.hostname || "this machine"));
        say(Qt.formatDateTime(new Date(), "ddd d MMM yyyy  HH:mm"));
        say("");
        say("users:    " + plm.users.list.map(u => u.name).join("  "));
        say("sessions: " + plm.sessions.list.map((s, i) => "[" + (i + 1) + "] " + s.name).join("  "));
        say("");
        say("type a number + Enter to pick a session, ↑↓ to change user, F12 to power off");
        say("");
    }

    Connections {
        target: root.auth
        function onFailed(message) {
            root.say("login: " + root.auth.user);
            root.say("password: ");
            root.say("** " + message.toLowerCase() + " **");
            root.say("");
        }
        function onLaunching() {
            root.say("login: " + root.auth.user);
            root.say("password: ");
            root.say("starting " + (root.auth.sessionInfo?.name ?? "session") + " ...");
        }
    }

    readonly property real cell: 18
    readonly property color fg: theme.text
    readonly property color dim: theme.textDim

    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 64
        width: parent.width - 128
        spacing: 2

        Repeater {
            model: root.log
            delegate: Text {
                required property string modelData
                text: modelData
                color: modelData.startsWith("**") ? root.theme.error : root.dim
                font.family: root.theme.mono
                font.pixelSize: root.cell
            }
        }

        // the live prompt
        RowLayout {
            spacing: 0
            Text {
                text: root.auth.phase === "prompt" ? root.auth.prompt.toLowerCase() + ": " : root.auth.user + "@" + (root.plm.keyboard.hostname || "plm") + " password: "
                color: root.fg
                font.family: root.theme.mono
                font.pixelSize: root.cell
                font.weight: Font.Bold
            }
            TextInput {
                id: field
                Layout.preferredWidth: 600
                color: root.fg
                font.family: root.theme.mono
                font.pixelSize: root.cell
                echoMode: root.auth.phase === "prompt" && root.auth.echo ? TextInput.Normal : TextInput.NoEcho
                cursorVisible: false
                enabled: !root.auth.busy
                Keys.onPressed: event => {
                    root.plm.activity.poke();
                    const k = event.key;
                    if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                        // a lone number picks a session
                        const n = parseInt(text);
                        if (/^\d$/.test(text) && n >= 1 && n <= root.plm.sessions.list.length) {
                            root.auth.selectSession(root.plm.sessions.list[n - 1].id);
                            root.say("session: " + root.plm.sessions.list[n - 1].name);
                            text = "";
                        } else {
                            root.auth.submit(text);
                            text = "";
                        }
                    } else if (k === Qt.Key_Up || k === Qt.Key_Down) {
                        root.auth.cycleUser(k === Qt.Key_Down ? 1 : -1);
                    } else if (k === Qt.Key_F12) {
                        root.plm.power.run("poweroff");
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }
        // block cursor that blinks
        Rectangle {
            Layout.topMargin: -root.cell * 1.15
            Layout.leftMargin: promptWidth.width
            width: root.cell * 0.6
            height: root.cell * 1.15
            color: root.fg
            visible: field.activeFocus
            opacity: blink.on ? 0.9 : 0
            Timer {
                id: blink
                property bool on: true
                interval: 530
                repeat: true
                running: true
                onTriggered: on = !on
            }
        }
        TextMetrics {
            id: promptWidth
            font.family: root.theme.mono
            font.pixelSize: root.cell
            font.weight: Font.Bold
            text: (root.auth.phase === "prompt" ? root.auth.prompt.toLowerCase() + ": " : root.auth.user + "@" + (root.plm.keyboard.hostname || "plm") + " password: ")
        }
    }

    // status line along the bottom, like a tmux bar
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 34
        color: root.theme.accent1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            Text {
                text: "[" + root.auth.user + "] " + (root.auth.sessionInfo?.name ?? "-")
                color: "#021a0a"
                font.family: root.theme.mono
                font.pixelSize: 14
                font.weight: Font.Bold
            }
            Text {
                visible: root.plm.keyboard.capsLock
                text: "  CAPS"
                color: "#5a0000"
                font.family: root.theme.mono
                font.pixelSize: 14
                font.weight: Font.Black
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (root.plm.power.hasBattery ? "bat " + root.plm.power.percent + "%  " : "") + Qt.formatTime(clock.now, "HH:mm")
                color: "#021a0a"
                font.family: root.theme.mono
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }
    }

    // scanlines
    Column {
        anchors.fill: parent
        opacity: 0.12
        Repeater {
            model: Math.ceil(root.height / 3)
            delegate: Rectangle {
                width: root.width
                height: 3
                color: index % 2 ? "transparent" : "black"
                required property int index
            }
        }
    }

    QtObject {
        id: clock
        property date now: new Date()
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: clock.now = new Date()
    }
}
