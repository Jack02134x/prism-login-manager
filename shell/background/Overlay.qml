import QtQuick
import qs.common

// Aurora wash, vignette and film grain over the background.
Item {
    id: root

    property real aurora: Theme.fx.aurora
    property real vignette: Theme.fx.vignette
    property real grain: Theme.fx.grain

    Loader {
        anchors.fill: parent
        active: root.aurora > 0.001
        sourceComponent: ShaderBg {
            shader: "aurora"
            opacity: root.aurora
            bg: "transparent"
        }
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.vignette > 0.001 || root.grain > 0.001
        readonly property real time: Motion.t
        readonly property real w: width
        readonly property real h: height
        property real vignette: root.vignette
        property real grain: root.grain
        fragmentShader: Qt.resolvedUrl("../shaders/overlay.frag.qsb")
    }
}
