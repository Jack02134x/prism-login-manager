import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Hostname, battery and caps lock, as glass pills.
RowLayout {
    id: root

    spacing: 8

    Chip {
        visible: !Config.greeter && Config.screenshot === ""
        icon: "flask"
        tint: Theme.accent3
        text: Config.editor ? "Preview" : "Test mode · Ctrl+Q quits"
    }
    Chip {
        visible: Theme.show.capsLock && Keyboard.capsLock
        icon: "keyboard_caps"
        tint: Theme.error
        text: "Caps Lock"
    }
    Chip {
        visible: Theme.show.hostname && Keyboard.hostname !== ""
        icon: "laptop"
        tint: Theme.accent2
        text: Keyboard.hostname
    }
    Chip {
        visible: Theme.show.battery && Power.hasBattery
        icon: Power.icon
        tint: Power.percent < 15 && !Power.charging ? Theme.error : Theme.accent1
        text: Power.percent + "%"
    }
}
