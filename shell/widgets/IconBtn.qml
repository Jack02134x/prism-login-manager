import QtQuick
import qs.common

// Round icon button. When `active` it morphs into a squircle filled with its
// accent colour (Material 3 expressive shape morph).
Rectangle {
    id: root

    property string icon: ""
    property real size: 40
    property real iconSize: Math.round(size * 0.5)
    property bool active: false
    property color accent: Theme.accent1
    property color idleColor: Theme.surface
    property color iconColor: active ? Theme.on(accent) : Theme.text
    property string tooltip: ""
    readonly property bool hovered: ia.containsMouse

    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: active ? size * 0.32 : size / 2
    color: active ? accent : idleColor
    border.width: active ? 0 : 1
    border.color: Theme.stroke
    scale: ia.pressed ? 0.86 : 1

    Behavior on radius { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatial } }
    Behavior on color { ColAnim {} }
    Behavior on scale { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatialFast } }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.iconColor
        Behavior on color { ColAnim {} }
    }

    Interactive {
        id: ia
        radius: root.radius
        tint: root.iconColor
        onClicked: root.clicked()
    }

    Tip {
        text: root.tooltip
        show: ia.containsMouse && root.tooltip !== ""
    }
}
