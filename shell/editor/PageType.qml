import QtQuick
import QtQuick.Layouts
import qs.common

// Fonts and the clock.
ColumnLayout {
    spacing: 14

    EdGroup {
        title: "Clock"
        EdSwitch { path: "clock.show"; label: "Show the clock" }
        EdChoice {
            path: "clock.format"
            label: "Time"
            options: [{ value: "HH:mm", label: "21:30" }, { value: "h:mm", label: "9:30" }, { value: "h:mm AP", label: "9:30 PM" }, { value: "HH\nmm", label: "21 / 30" }]
        }
        EdChoice {
            path: "clock.dateFormat"
            label: "Date"
            options: [{ value: "dddd, d MMMM", label: "Tuesday, 27 October" }, { value: "ddd d MMM", label: "Tue 27 Oct" }, { value: "yyyy-MM-dd", label: "2026-10-27" }, { value: "", label: "None" }]
        }
        EdText { path: "clock.dateFormat"; label: "Custom date"; mono: true; hint: "Qt date format" }
        EdSlider { path: "clock.size"; label: "Size"; from: 60; to: 360; step: 2; decimals: 0; suffix: "px" }
        EdChoice {
            path: "clock.weight"
            label: "Weight"
            options: [{ value: 300, label: "Light" }, { value: 500, label: "Medium" }, { value: 700, label: "Bold" }, { value: 900, label: "Black" }]
        }
        EdSwitch { path: "clock.gradient"; label: "Gradient fill" }
        EdSwitch { path: "clock.uppercaseDate"; label: "Upper-case date" }
        EdSlider { path: "clock.dateSpacing"; label: "Date spacing"; from: 0; to: 14; step: 0.5; decimals: 1 }
        EdSwitch { path: "clock.greeting"; label: "Greeting"; hint: "\"Good evening\"" }
    }

    EdGroup {
        title: "Fonts"
        EdFont { path: "fonts.display"; label: "Clock" }
        EdFont { path: "fonts.ui"; label: "Everything else" }
        EdFont { path: "fonts.mono"; label: "Monospace" }
    }
}
