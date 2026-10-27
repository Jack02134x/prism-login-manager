pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services
import qs.widgets

// Coverflow: every user is a card, tilted in 3D, with their own desktop's
// wallpaper on it (when they've synced with Prism). Flick, click or use the
// arrow keys; the field sits under the card in front.
Item {
    id: root

    property Item view: null
    property Item backdrop: null
    readonly property real amb: view?.ambientT ?? 0
    readonly property bool typing: login.typing
    readonly property real cardW: Math.min(320, width * 0.2)
    readonly property real cardH: cardW * 1.3

    function focusField() {
        login.focusField();
    }

    Clock {
        visible: Theme.clock.show
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 40 - size * 0.25
        anchors.topMargin: 12
        align: Qt.AlignLeft
        size: Theme.clock.size * 0.5
        scale: 1 + root.amb * 0.25
        transformOrigin: Item.TopLeft
    }

    StatusChips {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        opacity: 1 - root.amb
    }

    PathView {
        id: flow
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        width: parent.width
        height: root.cardH + 40
        opacity: 1 - root.amb
        model: Users.list
        pathItemCount: Math.min(7, Math.max(1, Users.list.length))
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: Motion.slow
        interactive: Users.list.length > 1
        currentIndex: Math.max(0, Users.names.indexOf(Auth.user))
        onCurrentIndexChanged: {
            const u = Users.list[currentIndex];
            if (u && u.name !== Auth.user && moving)
                Auth.selectUser(u.name);
        }
        // flicking breaks the currentIndex binding: follow ← → and the user menu by hand
        Connections {
            target: Auth
            function onUserChanged() {
                const i = Users.names.indexOf(Auth.user);
                if (i >= 0 && i !== flow.currentIndex)
                    flow.currentIndex = i;
            }
        }
        onMovementEnded: {
            const u = Users.list[currentIndex];
            if (u)
                Auth.selectUser(u.name);
        }

        path: Path {
            startX: flow.width * 0.5 - root.cardW * 3.2
            startY: flow.height / 2
            PathAttribute { name: "s"; value: 0.62 }
            PathAttribute { name: "a"; value: 58 }
            PathAttribute { name: "zz"; value: 0 }
            PathAttribute { name: "o"; value: 0.0 }
            PathLine { x: flow.width * 0.5 - root.cardW * 0.9; y: flow.height / 2 }
            PathAttribute { name: "s"; value: 0.82 }
            PathAttribute { name: "a"; value: 42 }
            PathAttribute { name: "zz"; value: 5 }
            PathAttribute { name: "o"; value: 0.85 }
            PathLine { x: flow.width * 0.5; y: flow.height / 2 }
            PathAttribute { name: "s"; value: 1.0 }
            PathAttribute { name: "a"; value: 0 }
            PathAttribute { name: "zz"; value: 10 }
            PathAttribute { name: "o"; value: 1.0 }
            PathLine { x: flow.width * 0.5 + root.cardW * 0.9; y: flow.height / 2 }
            PathAttribute { name: "s"; value: 0.82 }
            PathAttribute { name: "a"; value: -42 }
            PathAttribute { name: "zz"; value: 5 }
            PathAttribute { name: "o"; value: 0.85 }
            PathLine { x: flow.width * 0.5 + root.cardW * 3.2; y: flow.height / 2 }
            PathAttribute { name: "s"; value: 0.62 }
            PathAttribute { name: "a"; value: -58 }
            PathAttribute { name: "zz"; value: 0 }
            PathAttribute { name: "o"; value: 0.0 }
        }

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool current: PathView.isCurrentItem
            width: root.cardW
            height: root.cardH
            scale: PathView.s ?? 1
            z: PathView.zz ?? 0
            opacity: PathView.o ?? 1
            transform: Rotation {
                origin.x: card.width / 2
                origin.y: card.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: card.PathView.a ?? 0
            }

            // glow under the card in front
            Rectangle {
                anchors.fill: face
                anchors.margins: -18
                radius: face.radius + 18
                visible: card.current && Theme.fx.glow
                opacity: 0.45
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.accent1, 0.6) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.6) }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 48
                }
            }

            ClippingRectangle {
                id: face
                anchors.fill: parent
                radius: Theme.r.xl
                color: Theme.mix(Qt.color("#11131a"), Theme.accent1, 0.18)
                border.width: card.current ? 2 : 1
                border.color: card.current ? Theme.alpha(Theme.accent1, 0.8) : Theme.stroke

                // the person's own desktop, when they've run `plm sync`
                Image {
                    id: poster
                    anchors.fill: parent
                    source: card.modelData.poster ? "file://" + card.modelData.poster : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 640
                    asynchronous: true
                    cache: false
                }
                Rectangle {
                    anchors.fill: parent
                    visible: poster.status !== Image.Ready
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha(Theme.accent1, 0.35) }
                        GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.25) }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.35; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
                    }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 20
                    spacing: 10
                    Avatar {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.cardW * 0.42
                        Layout.preferredHeight: root.cardW * 0.42
                        user: card.modelData.name
                        spin: card.current && Theme.avatar.spin
                        glow: false
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: root.cardW - 40
                        text: card.modelData.real || card.modelData.name
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: "white"
                    }
                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        visible: card.modelData.real !== ""
                        text: card.modelData.name
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    flow.currentIndex = card.index;
                    Auth.selectUser(card.modelData.name);
                    root.focusField();
                }
            }
        }
    }

    LoginBox {
        id: login
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: flow.bottom
        anchors.topMargin: 24
        showAvatar: false
        showName: false
        opacity: 1 - root.amb
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        spacing: 10
        opacity: 1 - root.amb
        SessionMenu {}
        UserMenu {}
        Item { implicitWidth: 16 }
        PowerButtons { size: 38 }
    }
}
