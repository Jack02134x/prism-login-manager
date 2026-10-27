import QtQuick

// A plain text box in the editor's style (used by the fields below).
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool mono: false

    signal edited
    signal committed

    implicitHeight: 34
    radius: 10
    color: input.activeFocus ? Ed.fieldHover : Ed.field
    border.width: input.activeFocus ? 1 : 0
    border.color: Ed.accent

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Ed.text
        selectionColor: Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.4)
        font.family: root.mono ? Ed.mono : Ed.font
        font.pixelSize: 13
        clip: true
        selectByMouse: true
        onTextEdited: root.edited()
        onEditingFinished: root.committed()
        Keys.onEscapePressed: focus = false

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: root.placeholder
            color: Ed.faint
            font: input.font
        }
    }
}
