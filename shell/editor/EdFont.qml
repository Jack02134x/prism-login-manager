pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

// A font in the theme: shows the name in that font; opens a searchable list.
ColumnLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    readonly property string value: String(Theme.get(path) ?? "")
    property bool open: false

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        EdLabel {
            text: root.label
            hint: root.hint
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 10
            color: fma.containsMouse || root.open ? Ed.fieldHover : Ed.field
            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.value
                font.family: root.value
                font.pixelSize: 15
                color: Ed.text
                elide: Text.ElideRight
            }
            MouseArea {
                id: fma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.open = !root.open;
                    if (root.open)
                        search.input.forceActiveFocus();
                }
            }
        }
    }

    EdTextBox {
        id: search
        visible: root.open
        Layout.fillWidth: true
        placeholder: "Search fonts…"
    }

    Rectangle {
        visible: root.open
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        radius: Ed.radius
        color: Ed.bg
        clip: true
        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 4
            boundsBehavior: Flickable.StopAtBounds
            model: {
                const q = search.text.toLowerCase();
                const all = Qt.fontFamilies().filter(f => !f.startsWith("."));
                return q === "" ? all : all.filter(f => f.toLowerCase().includes(q));
            }
            delegate: Rectangle {
                id: row
                required property string modelData
                width: list.width
                height: 34
                radius: 8
                color: root.value === modelData ? Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.16) : rma.containsMouse ? Ed.field : "transparent"
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData
                    font.family: row.modelData
                    font.pixelSize: 15
                    color: Ed.text
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: rma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Theme.set(root.path, row.modelData);
                        root.open = false;
                    }
                }
            }
        }
    }
}
