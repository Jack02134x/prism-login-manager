import QtQuick
import QtQuick.Layouts
import qs.common

// Which layout, its panel, and what's shown.
ColumnLayout {
    spacing: 14

    EdGroup {
        title: "Layout"
        EdChoice {
            path: "layout"
            options: [
                { value: "prism", label: "Prism", icon: "view_dashboard" },
                { value: "glass", label: "Glass", icon: "dock_left" },
                { value: "minimal", label: "Minimal", icon: "format_text" },
                { value: "coverflow", label: "Coverflow", icon: "view_carousel" },
                { value: "custom", label: "Custom QML", icon: "code_braces" }
            ]
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Ed.faint
            font.family: Ed.font
            font.pixelSize: 12
            text: ({
                prism: "Prism's lock screen: a big gradient clock, the login card low in the middle.",
                glass: "Everything on one frosted panel at the side; the wallpaper stays free.",
                minimal: "A corner clock and one underlined line. Made for busy wallpapers and videos.",
                coverflow: "Each user is a 3D card showing their own synced desktop.",
                custom: "Loads Main.qml from the theme's folder. See themes/terminal for an example."
            })[Theme.layout] ?? ""
        }
        EdText {
            visible: Theme.layout === "custom"
            path: "main"
            label: "QML file"
            mono: true
        }
    }

    EdGroup {
        visible: Theme.layout === "glass"
        title: "Panel"
        EdChoice {
            path: "panel.side"
            label: "Side"
            options: [{ value: "left", label: "Left" }, { value: "right", label: "Right" }]
        }
        EdSlider { path: "panel.width"; label: "Width"; from: 320; to: 720; step: 10; decimals: 0; suffix: "px" }
        EdSlider { path: "panel.radius"; label: "Corners"; from: 0; to: 48; step: 1; decimals: 0; suffix: "px" }
        EdSlider { path: "panel.blur"; label: "Frost"; percent: true }
        EdSlider { path: "panel.opacity"; label: "Tint"; percent: true }
        EdSwitch { path: "panel.border"; label: "Outline" }
    }

    EdGroup {
        title: "Show"
        EdSwitch { path: "show.users"; label: "User picker" }
        EdSwitch { path: "show.sessions"; label: "Session picker" }
        EdSwitch { path: "show.power"; label: "Power buttons" }
        EdSwitch { path: "show.battery"; label: "Battery" }
        EdSwitch { path: "show.capsLock"; label: "Caps Lock warning" }
        EdSwitch { path: "show.hostname"; label: "Computer name" }
        EdSwitch { path: "show.hints"; label: "Key hints"; hint: "\"Enter to log in\" under the field" }
    }
}
