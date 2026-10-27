import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services
import qs.widgets

// Minimal: a clock in the corner and a single underlined line to type into.
// Everything else is small text up top. Made for busy wallpapers and videos.
Item {
    id: root

    property Item view: null
    property Item backdrop: null
    readonly property real amb: view?.ambientT ?? 0
    readonly property bool typing: login.typing
    readonly property real margin: Math.max(48, width * 0.045)

    function focusField() {
        login.focusField();
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.margin
        anchors.bottomMargin: root.margin
        spacing: 28

        Clock {
            visible: Theme.clock.show
            Layout.leftMargin: -size * 0.25
            align: Qt.AlignLeft
            size: Theme.clock.size * 0.8
        }

        RowLayout {
            spacing: 16
            opacity: 1 - root.amb
            Avatar {
                visible: Theme.avatar.show
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                Layout.alignment: Qt.AlignTop
                ring: 2
                glow: false
            }
            LoginBox {
                id: login
                align: Qt.AlignLeft
                showAvatar: false
                nameSize: 15
                spacing: 8
                fieldWidth: Math.min(380, root.width * 0.3)
                fieldHeight: 40
            }
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        spacing: 10
        opacity: (1 - root.amb) * 0.92
        StatusChips {}
        UserMenu { direction: "down" }
        SessionMenu { direction: "down" }
        PowerButtons { size: 36 }
    }
}
