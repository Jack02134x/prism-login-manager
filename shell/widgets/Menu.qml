pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

// A glass pop-up list anchored to an item. While open it moves itself onto the
// view's top layer (the item named "plmView"), so it also scales with the
// editor's preview. Click outside or press Esc to close.
Item {
    id: root

    property Item anchor: null
    property bool open: false
    // [{ icon, text, sub, active }]
    property var model: []
    property string title: ""
    // up | down
    property string direction: "up"
    property real menuWidth: 280

    signal picked(int index)

    function host() {
        let p = anchor;
        while (p && p.objectName !== "plmView")
            p = p.parent;
        return p ?? anchor?.parent ?? null;
    }
    function toggle() {
        if (open) {
            open = false;
        } else {
            const h = host();
            if (!h || !anchor)
                return;
            parent = h;
            const pt = anchor.mapToItem(h, 0, 0);
            card.x = Utils.clamp(pt.x + anchor.width / 2 - root.menuWidth / 2, 12, h.width - root.menuWidth - 12);
            card.y = direction === "up" ? pt.y - card.height - 10 : pt.y + anchor.height + 10;
            open = true;
            focusTrap.forceActiveFocus();
        }
    }

    anchors.fill: parent
    z: 1000
    visible: card.opacity > 0.01

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        acceptedButtons: Qt.AllButtons
        onClicked: root.open = false
    }

    FocusScope {
        id: focusTrap
        Keys.onEscapePressed: root.open = false
    }

    Rectangle {
        id: card
        width: root.menuWidth
        height: col.implicitHeight + 16
        radius: Theme.r.lg
        color: Theme.alpha(Theme.mix(Qt.color("#0c0e14"), Theme.accent1, 0.08), 0.9)
        border.width: 1
        border.color: Theme.stroke
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92
        transformOrigin: root.direction === "up" ? Item.Bottom : Item.Top
        Behavior on opacity { NumAnim { duration: Motion.fast } }
        Behavior on scale { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatial } }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 2

            Txt {
                visible: root.title !== ""
                Layout.leftMargin: 10
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                text: root.title.toUpperCase()
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Theme.textDim
            }

            Repeater {
                model: root.model
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: modelData.sub ? 52 : 42
                    radius: Theme.r.md
                    color: modelData.active ? Theme.alpha(Theme.accent1, 0.18) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        Icon {
                            visible: (row.modelData.icon ?? "") !== ""
                            icon: row.modelData.icon ?? ""
                            size: 18
                            color: row.modelData.active ? Theme.accent1 : Theme.textDim
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Txt {
                                Layout.fillWidth: true
                                text: row.modelData.text ?? ""
                                font.pixelSize: 14
                                font.weight: row.modelData.active ? Font.Bold : Font.Medium
                            }
                            Txt {
                                visible: (row.modelData.sub ?? "") !== ""
                                Layout.fillWidth: true
                                text: row.modelData.sub ?? ""
                                font.pixelSize: 11
                                color: Theme.textDim
                            }
                        }
                        Icon {
                            visible: row.modelData.active === true
                            icon: "check"
                            size: 16
                            color: Theme.accent1
                        }
                    }
                    Interactive {
                        radius: parent.radius
                        onClicked: {
                            root.open = false;
                            root.picked(row.index);
                        }
                    }
                }
            }
        }
    }
}
