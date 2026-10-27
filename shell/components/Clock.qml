import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.widgets

// The big clock: the time filled with the theme's gradient (or plain), the
// date underneath, and an optional greeting.
ColumnLayout {
    id: root

    property real size: Theme.clock.size
    property int align: Qt.AlignHCenter
    property bool showDate: true
    property bool gradient: Theme.clock.gradient
    property bool showGreeting: Theme.clock.greeting
    property int weight: Theme.clock.weight
    property color dateColor: Theme.text

    readonly property string format: {
        const f = Theme.clock.format || "HH:mm";
        return !Config.clock24h && f === "HH:mm" ? "h:mm" : f;
    }

    spacing: -root.size * 0.19

    Item {
        Layout.alignment: root.align
        implicitWidth: t.implicitWidth
        implicitHeight: t.implicitHeight

        Text {
            id: t
            text: Qt.formatTime(clock.date, root.format)
            font.family: Theme.display
            font.pixelSize: root.size
            font.weight: root.weight
            color: Theme.text
            visible: !root.gradient
            layer.enabled: root.gradient
            // room for the glyphs' overhang and the shadow, which the mask would clip
            topPadding: root.size * 0.3
            bottomPadding: root.size * 0.15
            leftPadding: root.size * 0.25
            rightPadding: root.size * 0.25
        }
        Rectangle {
            id: g
            anchors.fill: t
            visible: false
            layer.enabled: root.gradient
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.15; color: Theme.accent1 }
                GradientStop { position: 0.5; color: Theme.accent2 }
                GradientStop { position: 0.85; color: Theme.accent3 }
            }
        }
        MultiEffect {
            anchors.fill: t
            visible: root.gradient
            source: g
            maskEnabled: true
            maskSource: t
            maskThresholdMin: 0.3
            maskSpreadAtMin: 0.3
            shadowEnabled: true
            shadowBlur: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.6)
        }
    }

    Txt {
        visible: root.showDate && Theme.clock.dateFormat !== ""
        Layout.alignment: root.align
        Layout.leftMargin: root.align === Qt.AlignLeft ? root.size * 0.25 : 0
        text: {
            const d = Qt.formatDate(clock.date, Theme.clock.dateFormat);
            return Theme.clock.uppercaseDate ? d.toUpperCase() : d;
        }
        font.pixelSize: Math.max(13, root.size * 0.1)
        font.weight: Font.Bold
        font.letterSpacing: Theme.clock.dateSpacing
        color: root.dateColor
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.25)
    }

    Txt {
        visible: root.showGreeting
        Layout.alignment: root.align
        Layout.topMargin: root.size * 0.24
        Layout.leftMargin: root.align === Qt.AlignLeft ? root.size * 0.25 : 0
        text: Utils.greeting()
        font.pixelSize: Math.max(14, root.size * 0.09)
        color: Theme.textDim
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
