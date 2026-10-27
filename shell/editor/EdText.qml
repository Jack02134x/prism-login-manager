import QtQuick
import QtQuick.Layouts
import qs.common

// Text in the theme. Applies as you type (after a short pause).
RowLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    property string placeholder: ""
    property bool mono: false
    readonly property string value: String(Theme.get(path) ?? "")

    Layout.fillWidth: true
    spacing: 12

    EdLabel {
        visible: root.label !== ""
        text: root.label
        hint: root.hint
    }
    EdTextBox {
        id: box
        Layout.fillWidth: true
        placeholder: root.placeholder
        mono: root.mono
        text: root.value
        onEdited: apply.restart()
        onCommitted: root.commit()
    }
    // keep the box in step with undo/redo
    onValueChanged: if (!box.input.activeFocus) box.text = value

    Timer {
        id: apply
        interval: 450
        onTriggered: root.commit()
    }
    function commit() {
        apply.stop();
        Theme.set(path, box.text);
    }
}
