import QtQuick
import qs.common

// One background in the cross-fade stack: media, shader, gradient or colour.
// The background item keeps two of these and fades the new one in on top.
Item {
    id: root

    property string type: ""
    property string kind: ""
    property string source: ""
    property string poster: ""
    property bool front: false
    property bool playing: true
    readonly property var bg: Theme.bg

    readonly property bool ready: type === "media" ? (media.item?.ready ?? false) : type !== ""
    signal shown

    function setup(t, k, s, p) {
        type = t;
        kind = k;
        source = s;
        poster = p;
    }
    function clear() {
        setup("", "", "", "");
    }

    z: front ? 1 : 0
    visible: type !== ""
    opacity: front ? (ready ? 1 : 0) : 1
    Behavior on opacity {
        enabled: root.front
        NumberAnimation { duration: 900; easing.type: Easing.InOutCubic }
    }
    onOpacityChanged: if (front && opacity >= 1) shown()

    Loader {
        id: media
        anchors.fill: parent
        active: root.type === "media"
        sourceComponent: MediaLayer {
            kind: root.kind
            source: root.source
            poster: root.poster
            fill: root.bg.fill
            speed: root.bg.speed
            loop: root.bg.loop
            playing: root.playing
            reportFrame: root.front
        }
    }

    Loader {
        anchors.fill: parent
        active: root.type === "shader"
        sourceComponent: ShaderBg {
            shader: root.bg.shader
            speed: Math.round(root.bg.speed)
        }
    }

    // gradient: a big rotated square so any angle covers the screen
    Item {
        anchors.fill: parent
        visible: root.type === "gradient"
        clip: true
        Rectangle {
            anchors.centerIn: parent
            width: Math.hypot(parent.width, parent.height)
            height: width
            rotation: (root.bg.angle ?? 135) - 90
            gradient: Gradient {
                GradientStop { position: 0; color: root.bg.colors?.[0] ?? "#10131c" }
                GradientStop { position: 0.5; color: root.bg.colors?.[1] ?? root.bg.colors?.[0] ?? "#24163a" }
                GradientStop { position: 1; color: root.bg.colors?.[2] ?? root.bg.colors?.[1] ?? "#0b2730" }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.type === "color"
        color: root.bg.colors?.[0] ?? "#10131c"
    }
}
