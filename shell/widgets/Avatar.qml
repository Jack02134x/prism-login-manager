import QtQuick
import Quickshell.Widgets
import qs.common
import qs.services

// A user's picture inside a (spinning) gradient ring. Tries each source in
// turn and falls back to the person's initials.
Item {
    id: root

    property string user: Auth.user
    property var sources: Users.avatars(user)
    property real ring: Theme.avatar.ringWidth
    // circle | squircle | square
    property string shape: Theme.avatar.shape
    // gradient | accent | none
    property string ringStyle: Theme.avatar.ring
    property bool spin: Theme.avatar.spin
    property bool glow: Theme.fx.glow

    property int tried: 0
    onSourcesChanged: tried = 0

    implicitWidth: 96
    implicitHeight: 96

    function radiusFor(w) {
        return shape === "circle" ? w / 2 : shape === "squircle" ? w * 0.3 : w * 0.12;
    }

    // soft glow behind
    Rectangle {
        visible: root.glow && root.ringStyle !== "none"
        anchors.centerIn: parent
        width: parent.width * 1.5
        height: width
        radius: width / 2
        opacity: 0.35
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.accent1, 0.0) }
            GradientStop { position: 0.5; color: Theme.alpha(Theme.accent2, 0.5) }
            GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.0) }
        }
        rotation: Motion.t * 360 * 2
    }

    ClippingRectangle {
        visible: root.ringStyle !== "none"
        anchors.fill: parent
        radius: root.radiusFor(width)
        color: "transparent"
        Rectangle {
            // a square larger than the ring, so rotating it never shows corners
            anchors.centerIn: parent
            width: parent.width * 1.5
            height: width
            rotation: root.spin ? Motion.t * 360 * 4 : 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.ringStyle === "accent" ? Theme.accent1 : Theme.accent1 }
                GradientStop { position: 0.5; color: root.ringStyle === "accent" ? Theme.accent1 : Theme.accent2 }
                GradientStop { position: 1; color: root.ringStyle === "accent" ? Theme.accent1 : Theme.accent3 }
            }
        }
    }

    ClippingRectangle {
        id: pic
        anchors.fill: parent
        anchors.margins: root.ringStyle === "none" ? 0 : root.ring + 2
        radius: root.radiusFor(width)
        color: Theme.mix(Qt.color("#16181f"), Theme.accent1, 0.25)

        Image {
            id: img
            anchors.fill: parent
            source: root.tried < root.sources.length ? root.sources[root.tried] : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 256
            sourceSize.height: 256
            asynchronous: true
            cache: false
            onStatusChanged: if (status === Image.Error) root.tried++
        }

        Txt {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: Utils.initials(Users.displayName(root.user))
            font.family: Theme.display
            font.pixelSize: parent.width * 0.38
            font.weight: Font.Black
            color: Theme.accent1
        }
    }
}
