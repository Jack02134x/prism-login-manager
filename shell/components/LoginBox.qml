import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Avatar, name and the login field, with every state the login can be in:
// typing, checking, a second prompt from PAM, wrong password (shake),
// caps lock, and typing a user name that isn't listed.
ColumnLayout {
    id: root

    property bool showAvatar: Theme.avatar.show
    property real avatarSize: Theme.avatar.size
    property bool showName: true
    property real fieldWidth: Theme.input.width
    property real fieldHeight: Theme.input.height
    property int align: Qt.AlignHCenter
    property real nameSize: 22
    property bool showStatus: true
    readonly property bool typing: field.text.length > 0
    // typing a user name instead of a password
    property bool manual: false

    function focusField() {
        field.focusInput();
    }

    spacing: 16

    Connections {
        target: Auth
        function onFailed() {
            field.text = "";
            shake.restart();
            root.focusField();
        }
        function onPhaseChanged() {
            if (Auth.phase === "prompt" || Auth.phase === "idle") {
                field.text = "";
                root.focusField();
            }
        }
        function onUserChanged() {
            field.text = "";
            root.manual = false;
        }
    }
    Connections {
        target: Activity
        function onOtherUserRequested() {
            root.manual = true;
            field.text = "";
            root.focusField();
        }
    }

    Avatar {
        visible: root.showAvatar
        Layout.alignment: root.align
        Layout.preferredWidth: root.avatarSize
        Layout.preferredHeight: root.avatarSize
        scale: Auth.phase === "busy" ? 0.94 : 1
        Behavior on scale { NumAnim { duration: Motion.slow; easing.bezierCurve: Motion.spatial } }
    }

    Txt {
        visible: root.showName
        Layout.alignment: root.align
        text: root.manual ? "Who's there?" : Users.displayName(Auth.user) || "Welcome"
        font.pixelSize: root.nameSize
        font.weight: Font.Black
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.2)
    }

    Item {
        Layout.alignment: root.align
        implicitWidth: root.fieldWidth
        implicitHeight: root.fieldHeight
        transform: Translate { id: shakeT }

        InputField {
            id: field
            anchors.fill: parent
            password: !root.manual && !(Auth.phase === "prompt" && Auth.echo)
            icon: root.manual ? "account" : Auth.phase === "prompt" ? "shield_key" : "lock"
            busy: Auth.busy
            placeholder: root.manual ? "User name" : Auth.phase === "prompt" ? Auth.prompt : Theme.input.placeholder
            accent: Auth.error !== "" ? Theme.error : Theme.accent1
            onAccepted: {
                if (root.manual) {
                    root.manual = false;
                    Auth.selectUser(text);
                    text = "";
                    return;
                }
                const t = text;
                if (t.length === 0 && Auth.phase !== "prompt")
                    return;
                Auth.submit(t);
                // keep the dots on screen while it checks
            }
            onEscaped: {
                if (root.manual)
                    root.manual = false;
                else if (Auth.phase === "prompt")
                    Auth.cancel();
                text = "";
            }
            onNavigate: delta => Auth.cycleUser(delta)
        }

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shakeT; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 14; duration: 90 }
            NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
        }
    }

    Txt {
        visible: root.showStatus
        Layout.alignment: root.align
        Layout.maximumWidth: root.fieldWidth + 80
        horizontalAlignment: root.align === Qt.AlignLeft ? Text.AlignLeft : Text.AlignHCenter
        text: {
            if (Auth.error !== "")
                return Auth.error;
            if (Theme.show.capsLock && Keyboard.capsLock)
                return "Caps Lock is on";
            if (Auth.phase === "launching")
                return "Starting " + (Auth.sessionInfo?.name ?? "your session") + "…";
            if (Auth.phase === "busy")
                return "Checking…";
            if (Auth.info !== "")
                return Auth.info;
            if (!Theme.show.hints)
                return "";
            if (root.manual)
                return "Enter to continue · Esc to go back";
            return Users.list.length > 1 ? "Enter to log in · ← → to switch user" : "Enter to log in";
        }
        color: Auth.error !== "" ? Theme.error : (Keyboard.capsLock && Theme.show.capsLock) ? Theme.accent3 : Theme.alpha(Theme.text, 0.62)
        font.pixelSize: 12
        font.weight: Auth.error !== "" || Keyboard.capsLock ? Font.Bold : Font.Normal
        wrapMode: Text.WordWrap
    }
}
