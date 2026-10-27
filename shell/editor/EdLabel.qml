import QtQuick
import QtQuick.Layouts

// A field's label, with an optional hint underneath.
ColumnLayout {
    id: root

    property string text: ""
    property string hint: ""

    spacing: 1
    Layout.preferredWidth: 128
    Layout.maximumWidth: 128
    Layout.alignment: Qt.AlignTop

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 7
        text: root.text
        color: Ed.text
        font.family: Ed.font
        font.pixelSize: 13
        font.weight: Font.Medium
        elide: Text.ElideRight
    }
    Text {
        visible: root.hint !== ""
        Layout.fillWidth: true
        text: root.hint
        color: Ed.faint
        font.family: Ed.font
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
