pragma Singleton

import QtQuick
import Quickshell

// Durations, Material 3 expressive curves, and one shared ambient clock.
Singleton {
    id: root

    readonly property int fast: 160
    readonly property int normal: 320
    readonly property int slow: 520
    readonly property int slower: 800

    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> decel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> accel: [0.3, 0, 0.8, 0.15, 1, 1]
    // springy curves that overshoot slightly
    readonly property list<real> spatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property list<real> spatialFast: [0.42, 1.67, 0.21, 0.9, 1, 1]

    // Looping 0..1 phase shared by every ambient effect (shaders, rings, glows).
    // It steps on the display's own frames, so shader backgrounds stay smooth.
    readonly property real period: 24000
    property real t: 0
    property bool paused: false

    FrameAnimation {
        running: !root.paused
        onTriggered: root.t = (root.t + frameTime * 1000 / root.period) % 1
    }
}
