pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// Where the accents come from, and the fixed colours.
ColumnLayout {
    spacing: 14

    EdGroup {
        title: "Accents"
        note: "Used for the clock gradient, the avatar ring, the field and the glow."
        EdChoice {
            path: "colors.source"
            options: [
                { value: "auto", label: "Automatic", icon: "auto_fix" },
                { value: "prism", label: "Prism palette", icon: "palette" },
                { value: "wallpaper", label: "From wallpaper", icon: "eyedropper" },
                { value: "custom", label: "My colours", icon: "select_color" }
            ]
        }
        RowLayout {
            spacing: 8
            Text {
                text: "Now:"
                color: Ed.dim
                font.family: Ed.font
                font.pixelSize: 12
            }
            Repeater {
                model: [Theme.accent1, Theme.accent2, Theme.accent3]
                delegate: Rectangle {
                    required property color modelData
                    width: 40
                    height: 22
                    radius: 7
                    color: modelData
                }
            }
            Text {
                text: "(" + ({ prism: "Prism palette", wallpaper: "wallpaper", custom: "your colours" })[Theme.paletteSource] + ")"
                color: Ed.faint
                font.family: Ed.font
                font.pixelSize: 12
            }
        }
        EdColor { path: "colors.accent"; label: "Accent 1"; hint: Theme.paletteSource === "custom" ? "" : "used when nothing else is" }
        EdColor { path: "colors.accent2"; label: "Accent 2" }
        EdColor { path: "colors.accent3"; label: "Accent 3" }
    }

    EdGroup {
        title: "Text & surfaces"
        EdColor { path: "colors.text"; label: "Text" }
        EdColor { path: "colors.textDim"; label: "Quiet text" }
        EdColor { path: "colors.surface"; label: "Pills & field" }
        EdSlider { path: "colors.surfaceAlpha"; label: "Their opacity"; percent: true }
        EdSlider { path: "colors.border"; label: "Outlines"; from: 0; to: 0.6; percent: true }
        EdColor { path: "colors.error"; label: "Errors" }
    }
}
