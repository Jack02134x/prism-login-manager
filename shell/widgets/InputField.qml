import QtQuick
import qs.common
import qs.services

// The login field: glass, solid or underline style, an animated focus outline,
// a peek button for the password, and dots that pop in as you type.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property string icon: "lock"
    property color accent: Theme.accent1
    property bool password: true
    property bool peek: false
    property real fontSize: 16
    // glass | solid | underline
    property string style: Theme.input.style
    property bool busy: false

    signal accepted
    signal escaped
    signal navigate(int delta)
    signal activity

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 360
    implicitHeight: 52
    radius: style === "underline" ? 0 : Theme.input.radius
    color: style === "underline" ? "transparent" : style === "solid" ? Theme.alpha(Theme.mix(Qt.color(Theme.col.surface), accent, 0.12), 0.92) : Theme.surface
    border.width: style === "underline" ? 0 : input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? accent : Theme.stroke
    Behavior on border.color { ColAnim {} }

    // underline style: a line that grows from the middle when focused
    Rectangle {
        visible: root.style === "underline"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 1
        color: Theme.stroke
    }
    Rectangle {
        visible: root.style === "underline"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: input.activeFocus ? parent.width : 0
        height: 2
        color: root.accent
        Behavior on width { NumAnim { duration: Motion.slow; easing.bezierCurve: Motion.emphasized } }
    }

    Icon {
        id: ico
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: root.style === "underline" ? 2 : 18
        anchors.verticalCenter: parent.verticalCenter
        icon: root.busy ? "loading" : root.icon
        size: 18
        color: input.activeFocus ? root.accent : Theme.textDim
        RotationAnimation on rotation {
            running: root.busy
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            onStopped: ico.rotation = 0
        }
    }

    TextInput {
        id: input
        anchors.left: ico.visible ? ico.right : parent.left
        anchors.leftMargin: ico.visible ? 12 : 18
        anchors.right: peekBtn.visible ? peekBtn.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: root.fontSize
        font.letterSpacing: root.password && !root.peek ? 3 : 0
        selectionColor: Theme.alpha(root.accent, 0.4)
        selectedTextColor: Theme.text
        echoMode: root.password && !root.peek ? TextInput.Password : TextInput.Normal
        passwordCharacter: Theme.input.mask
        passwordMaskDelay: 0
        clip: true
        enabled: !root.busy
        Keys.onPressed: event => {
            root.activity();
            Activity.poke();
            const k = event.key;
            if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                root.accepted();
            } else if (k === Qt.Key_Escape) {
                root.escaped();
            } else if ((k === Qt.Key_Left || k === Qt.Key_Right) && input.text.length === 0) {
                root.navigate(k === Qt.Key_Right ? 1 : -1);
            } else {
                return;
            }
            event.accepted = true;
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.alpha(Theme.textDim, 0.75)
            font.pixelSize: root.fontSize
            font.letterSpacing: 0
            width: parent.width
            visible: input.text.length === 0
        }
    }

    Icon {
        id: peekBtn
        visible: root.password && input.text.length > 0
        anchors.right: parent.right
        anchors.rightMargin: root.style === "underline" ? 2 : 16
        anchors.verticalCenter: parent.verticalCenter
        icon: root.peek ? "eye_off_outline" : "eye_outline"
        size: 18
        color: peekArea.containsMouse ? Theme.text : Theme.textDim
        MouseArea {
            id: peekArea
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.peek = !root.peek;
                input.forceActiveFocus();
            }
        }
    }
}
