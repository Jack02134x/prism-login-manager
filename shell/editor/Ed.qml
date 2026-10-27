pragma Singleton

import QtQuick
import Quickshell
import qs.common

// The editor's own look: fixed dark surfaces (so editing a theme's colours never
// makes the editor unreadable), with the theme's accent for highlights.
Singleton {
    readonly property color bg: "#0d0f14"
    readonly property color panel: "#13161d"
    readonly property color card: "#191d27"
    readonly property color field: "#202533"
    readonly property color fieldHover: "#272d3d"
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.07)
    readonly property color text: "#e9ebf2"
    readonly property color dim: "#9aa1b5"
    readonly property color faint: "#646b80"
    readonly property color accent: Theme.ready ? Theme.mix(Theme.accent1, Qt.color("#ffffff"), 0.1) : "#82d5ca"
    readonly property color danger: "#ff8a80"
    readonly property string font: "Adwaita Sans"
    readonly property string mono: "Adwaita Mono"
    readonly property int radius: 12
}
