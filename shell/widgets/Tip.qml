import QtQuick
import qs.common

// Small tooltip above its parent.
Rectangle {
    id: root

    property string text: ""
    property bool show: false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.top
    anchors.bottomMargin: 8
    implicitWidth: label.implicitWidth + 18
    implicitHeight: 26
    radius: 13
    color: Qt.rgba(0, 0, 0, 0.72)
    opacity: show ? 1 : 0
    visible: opacity > 0
    z: 100
    Behavior on opacity { NumAnim { duration: Motion.fast } }

    Txt {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 12
        color: "white"
    }
}
