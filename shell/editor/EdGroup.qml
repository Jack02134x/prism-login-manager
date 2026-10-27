import QtQuick
import QtQuick.Layouts

// A titled card that groups related fields.
Rectangle {
    id: root

    property string title: ""
    property string note: ""
    default property alias content: col.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 32
    radius: Ed.radius + 4
    color: Ed.card
    border.width: 1
    border.color: Ed.stroke

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        Text {
            visible: root.title !== ""
            text: root.title.toUpperCase()
            color: Ed.dim
            font.family: Ed.font
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.6
        }
        Text {
            visible: root.note !== ""
            Layout.fillWidth: true
            text: root.note
            color: Ed.faint
            font.family: Ed.font
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
        }
    }
}
