import QtQuick
import QtQuick.Layouts
import qs.common

// A small glass pill: icon + text. Clickable when `clickable`.
Rectangle {
    id: root

    property string icon: ""
    property color tint: Theme.accent1
    property string text: ""
    property bool clickable: false
    property bool trailingChevron: false
    property real fontSize: 13
    readonly property bool hovered: ia.containsMouse

    signal clicked

    implicitWidth: row.implicitWidth + 26
    implicitHeight: 34
    radius: height / 2
    color: Theme.surface
    border.width: 1
    border.color: Theme.alpha(tint, 0.35)
    scale: ia.pressed ? 0.95 : 1
    Behavior on scale { NumAnim { duration: Motion.fast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Icon {
            visible: root.icon !== ""
            icon: root.icon
            size: 16
            color: root.tint
        }
        Txt {
            text: root.text
            font.pixelSize: root.fontSize
            font.weight: Font.DemiBold
        }
        Icon {
            visible: root.trailingChevron
            icon: "chevron_up"
            size: 14
            color: Theme.textDim
        }
    }

    Interactive {
        id: ia
        visible: root.clickable
        radius: root.radius
        onClicked: root.clicked()
    }
}
