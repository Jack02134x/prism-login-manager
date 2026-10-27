import QtQuick
import QtQuick.Layouts
import qs.widgets

// Editor button: icon and/or text; `primary` fills it with the accent.
Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool primary: false
    property bool danger: false
    property bool checked: false
    property string tooltip: ""
    readonly property color fg: primary ? "#0d0f14" : danger ? Ed.danger : checked ? Ed.accent : Ed.text

    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + (text !== "" ? 26 : 18)
    radius: Ed.radius
    color: primary ? Ed.accent : checked ? Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.16) : ma.containsMouse ? Ed.fieldHover : Ed.field
    border.width: checked && !primary ? 1 : 0
    border.color: Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.5)
    opacity: enabled ? 1 : 0.4
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumAnim { duration: 120 } }
    Behavior on color { ColAnim {} }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Icon {
            visible: root.icon !== ""
            icon: root.icon
            size: 16
            color: root.fg
            bounce: false
        }
        Text {
            visible: root.text !== ""
            text: root.text
            color: root.fg
            font.family: Ed.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    EdTip {
        text: root.tooltip
        show: ma.containsMouse && root.tooltip !== ""
    }
}
