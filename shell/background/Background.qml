import QtQuick
import QtQuick.Effects
import qs.common
import qs.widgets

// The whole backdrop: the theme's background (cross-fading whenever it changes,
// e.g. when another user with a different synced wallpaper is picked), with
// zoom, mouse parallax, blur, saturation and dim on top.
Item {
    id: root

    // added to the theme's blur (typing, ambient mode)
    property real extraBlur: 0
    // pointer position 0..1 for parallax
    property real px: 0.5
    property real py: 0.5
    property bool playing: true
    readonly property var bg: Theme.bg
    readonly property real blurAmount: Utils.clamp(Theme.bgBlur + extraBlur, 0, 1)

    clip: true

    readonly property string key: Theme.ready ? Theme.bgType + "|" + Theme.bgKind + "|" + Theme.bgSource + "|" + Theme.bgPoster : ""
    property bool aFront: false
    onKeyChanged: if (key !== "") Qt.callLater(swap)
    Component.onCompleted: if (key !== "") swap()

    function swap() {
        const next = aFront ? layerB : layerA;
        const cur = aFront ? layerA : layerB;
        if (cur.type === Theme.bgType && cur.kind === Theme.bgKind && cur.source === Theme.bgSource && cur.poster === Theme.bgPoster && cur.type !== "")
            return;
        next.setup(Theme.bgType, Theme.bgKind, Theme.bgSource, Theme.bgPoster);
        aFront = !aFront;
    }

    Item {
        id: content
        anchors.fill: parent
        visible: !fx.visible

        Item {
            id: mover
            anchors.fill: parent
            // a little overscan so parallax and blur never show an edge
            scale: root.bg.zoom + root.bg.parallax * 0.05 + root.blurAmount * 0.06
            Behavior on scale { NumAnim { duration: Motion.slower } }
            transform: Translate {
                x: (0.5 - root.px) * root.bg.parallax * root.width * 0.04
                y: (0.5 - root.py) * root.bg.parallax * root.height * 0.04
                Behavior on x { NumAnim { duration: 900 } }
                Behavior on y { NumAnim { duration: 900 } }
            }

            BgLayer {
                id: layerA
                anchors.fill: parent
                front: root.aFront
                playing: root.playing
                onShown: layerB.clear()
            }
            BgLayer {
                id: layerB
                anchors.fill: parent
                front: !root.aFront
                playing: root.playing
                onShown: layerA.clear()
            }
        }
    }

    MultiEffect {
        id: fx
        anchors.fill: content
        source: content
        visible: root.blurAmount > 0.004 || root.bg.saturation !== 0
        autoPaddingEnabled: false
        blurEnabled: root.blurAmount > 0.004
        blur: root.blurAmount
        blurMax: 64
        saturation: root.bg.saturation
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.bg.dim
    }
}
