import QtQuick
import qs.common

// Animated shader backdrop: aurora | prism | mesh. Colours follow the theme.
ShaderEffect {
    id: root

    property string shader: "aurora"
    property real intensity: 1
    property int speed: 1
    property color c1: Theme.accent1
    property color c2: Theme.accent2
    property color c3: Theme.accent3
    property color bg: Qt.color(Theme.bg.colors?.[0] ?? "#10131c")

    readonly property real time: (Motion.t * Math.max(1, speed)) % 1
    readonly property real w: width
    readonly property real h: height

    readonly property var known: ["aurora", "prism", "mesh"]
    fragmentShader: Qt.resolvedUrl("../shaders/" + (known.includes(shader) ? shader : "aurora") + ".frag.qsb")
}
