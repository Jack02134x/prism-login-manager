import QtQuick
import QtQuick.Layouts
import qs.common

// A yes/no in the theme.
RowLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    readonly property bool checked: Theme.get(path) === true

    Layout.fillWidth: true
    spacing: 12

    EdLabel {
        Layout.preferredWidth: -1
        Layout.maximumWidth: 9999
        Layout.fillWidth: true
        text: root.label
        hint: root.hint
    }

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: 3
        implicitWidth: 44
        implicitHeight: 24
        radius: 12
        color: root.checked ? Ed.accent : Ed.field
        Behavior on color { ColorAnimation { duration: 160 } }
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? "#0d0f14" : Ed.dim
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Theme.set(root.path, !root.checked)
        }
    }
}
