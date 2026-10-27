import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.common

// Frosted glass: the background behind this item, blurred, under a tinted pane.
// `backdrop` is the view's background item (layouts get it as `backdrop`).
Item {
    id: root

    property Item backdrop: null
    property real blur: Theme.panel.blur
    property real radius: Theme.panel.radius
    property color tint: Theme.alpha(Qt.color(Theme.col.surface), Theme.panel.opacity)
    property bool border: Theme.panel.border
    default property alias content: inner.data

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"

        ShaderEffectSource {
            id: grab
            anchors.fill: parent
            visible: false
            sourceItem: root.backdrop
            live: true
            recursive: false
            sourceRect: {
                if (!root.backdrop)
                    return Qt.rect(0, 0, 0, 0);
                // mapToItem isn't tracked: name the geometry so the grab follows the panel as it slides
                void (root.x + root.y + root.width + root.height + (root.parent?.width ?? 0));
                const p = root.mapToItem(root.backdrop, 0, 0, root.width, root.height);
                return Qt.rect(p.x, p.y, p.width, p.height);
            }
        }
        MultiEffect {
            anchors.fill: parent
            visible: root.backdrop !== null && root.blur > 0
            source: grab
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.blur
            blurMax: 64
            saturation: 0.2
        }
        Rectangle {
            anchors.fill: parent
            color: root.tint
        }
        // a faint sheen from the top-left
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: Theme.alpha(Theme.accent1, 0.10) }
                GradientStop { position: 0.6; color: Theme.alpha(Theme.accent2, 0.03) }
                GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.06) }
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: root.border
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.stroke
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
