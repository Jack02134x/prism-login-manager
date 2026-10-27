import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Prism: the lock screen's look. A big gradient clock up top, the login card
// low in the middle, users and sessions bottom-left, power bottom-right.
// Ambient mode leaves only the clock, drifted down to the centre.
Item {
    id: root

    property Item view: null
    property Item backdrop: null
    readonly property real amb: view?.ambientT ?? 0
    readonly property bool typing: login.typing

    function focusField() {
        login.focusField();
    }

    Clock {
        visible: Theme.clock.show
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.09 + root.amb * (parent.height * 0.5 - implicitHeight / 2 - parent.height * 0.09)
        scale: 1 + root.amb * 0.12
    }

    StatusChips {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        opacity: 1 - root.amb
    }

    LoginBox {
        id: login
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        opacity: 1 - root.amb
        transform: Translate { y: root.amb * 60 }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 10
        opacity: 1 - root.amb
        UserMenu {}
        SessionMenu {}
    }

    PowerButtons {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        opacity: 1 - root.amb
    }
}
