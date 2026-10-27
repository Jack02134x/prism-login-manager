pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Caps lock (read from its LED, Wayland clients can't ask for it) and the hostname.
Singleton {
    id: root

    property string ledPath: ""
    property bool led: false
    // the editor's "simulate caps lock" switch
    property bool simulateCaps: false
    readonly property bool capsLock: led || simulateCaps
    property string hostname: ""

    Process {
        running: true
        command: [Config.helper, "caps"]
        stdout: StdioCollector {
            onStreamFinished: root.ledPath = text.trim()
        }
    }
    Process {
        running: true
        command: [Config.helper, "host"]
        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    FileView {
        id: ledFile
        path: root.ledPath
        printErrors: false
        onLoaded: root.led = text().trim() !== "0"
    }
    // sysfs has no change events: poll the LED (a 1-byte read)
    Timer {
        interval: 400
        repeat: true
        running: root.ledPath !== ""
        onTriggered: ledFile.reload()
    }
}
