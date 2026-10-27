pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets

// One of a few values, as pills. options: [{ value, label, icon }]
RowLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    property var options: []
    readonly property var value: Theme.get(path)

    Layout.fillWidth: true
    spacing: 12

    EdLabel {
        visible: root.label !== ""
        text: root.label
        hint: root.hint
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: pill
                required property var modelData
                readonly property bool on: JSON.stringify(root.value) === JSON.stringify(modelData.value)
                implicitWidth: prow.implicitWidth + 22
                implicitHeight: 32
                radius: 10
                color: on ? Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.18) : pma.containsMouse ? Ed.fieldHover : Ed.field
                border.width: on ? 1 : 0
                border.color: Ed.accent
                Behavior on color { ColorAnimation { duration: 140 } }
                RowLayout {
                    id: prow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        visible: (pill.modelData.icon ?? "") !== ""
                        icon: pill.modelData.icon ?? ""
                        size: 15
                        color: pill.on ? Ed.accent : Ed.dim
                        bounce: false
                    }
                    Text {
                        text: pill.modelData.label ?? String(pill.modelData.value)
                        color: pill.on ? Ed.text : Ed.dim
                        font.family: Ed.font
                        font.pixelSize: 12
                        font.weight: pill.on ? Font.Bold : Font.Medium
                    }
                }
                MouseArea {
                    id: pma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.set(root.path, pill.modelData.value)
                }
            }
        }
    }
}
