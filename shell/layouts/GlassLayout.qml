import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.widgets

// Glass: everything on one frosted panel at the side, the wallpaper free on
// the other. Ambient mode slides the panel away and shows a large clock.
Item {
    id: root

    property Item view: null
    property Item backdrop: null
    readonly property real amb: view?.ambientT ?? 0
    readonly property bool typing: login.typing
    readonly property bool leftSide: Theme.panel.side !== "right"
    readonly property real gap: 24

    function focusField() {
        login.focusField();
    }

    Glass {
        id: panel
        backdrop: root.backdrop
        width: Math.min(Theme.panel.width, root.width - root.gap * 2)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: root.gap
        x: (root.leftSide ? root.gap : root.width - width - root.gap) + root.amb * (width + root.gap * 2) * (root.leftSide ? -1 : 1)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 18

            Clock {
                visible: Theme.clock.show
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: -size * 0.25
                align: Qt.AlignLeft
                size: Theme.clock.size * 0.46
            }

            Item { Layout.fillHeight: true }

            LoginBox {
                id: login
                Layout.alignment: Qt.AlignHCenter
                fieldWidth: panel.width - 72
                avatarSize: Theme.avatar.size * 0.9
            }

            Item { Layout.fillHeight: true }

            Flow {
                Layout.fillWidth: true
                spacing: 8
                UserMenu {}
                SessionMenu {}
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.stroke
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                StatusChips {
                    Layout.fillWidth: true
                    Layout.maximumWidth: panel.width - 72 - power.implicitWidth - 8
                    clip: true
                }
                PowerButtons {
                    id: power
                    size: 38
                }
            }
        }
    }

    Clock {
        visible: Theme.clock.show && root.amb > 0.01
        opacity: root.amb
        anchors.centerIn: parent
        scale: 0.9 + root.amb * 0.1
    }
}
