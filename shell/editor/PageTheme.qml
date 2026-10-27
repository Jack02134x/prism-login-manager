pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Name, author and description, and every theme on the system to open.
ColumnLayout {
    id: root

    signal open(string dir)

    spacing: 14

    EdGroup {
        title: "About this theme"
        EdText { path: "name"; label: "Name" }
        EdText { path: "author"; label: "Author" }
        EdText { path: "description"; label: "Description" }
    }

    EdGroup {
        title: "Themes"
        note: "Bundled themes are read-only: saving one makes your own copy in ~/.local/share/plm/themes."

        Repeater {
            model: Themes.list
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool current: modelData.dir === Theme.dir
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Ed.radius
                color: current ? Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.14) : tma.containsMouse ? Ed.fieldHover : Ed.field
                border.width: current ? 1 : 0
                border.color: Ed.accent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Icon {
                        icon: row.modelData.user ? "account" : row.modelData.system ? "shield_lock" : "package_variant"
                        size: 18
                        color: row.current ? Ed.accent : Ed.dim
                        bounce: false
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: row.modelData.name
                            color: Ed.text
                            font.family: Ed.font
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: (row.modelData.user ? "yours" : row.modelData.system ? "installed" : "bundled") + " · " + row.modelData.id
                            color: Ed.faint
                            font.family: Ed.font
                            font.pixelSize: 11
                        }
                    }
                    Text {
                        visible: row.modelData.id === Config.theme && !row.modelData.user
                        text: "LOGIN"
                        color: Ed.accent
                        font.family: Ed.font
                        font.pixelSize: 10
                        font.weight: Font.Black
                        font.letterSpacing: 1.5
                    }
                }
                MouseArea {
                    id: tma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.open(row.modelData.dir)
                }
            }
        }
    }
}
