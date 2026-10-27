import QtQuick

Rectangle {
    id: root

    property string text: ""
    property bool show: false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.bottom
    anchors.topMargin: 6
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24
    radius: 8
    color: "#000000"
    opacity: show ? 0.92 : 0
    visible: opacity > 0
    z: 100
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "white"
        font.family: Ed.font
        font.pixelSize: 11
    }
}
