import QtQuick
import QtQuick.Layouts
import qs.common

// The avatar and the password field.
ColumnLayout {
    spacing: 14

    EdGroup {
        title: "Avatar"
        EdSwitch { path: "avatar.show"; label: "Show the avatar" }
        EdSlider { path: "avatar.size"; label: "Size"; from: 48; to: 220; step: 2; decimals: 0; suffix: "px" }
        EdChoice {
            path: "avatar.shape"
            label: "Shape"
            options: [{ value: "circle", label: "Circle" }, { value: "squircle", label: "Squircle" }, { value: "square", label: "Square" }]
        }
        EdChoice {
            path: "avatar.ring"
            label: "Ring"
            options: [{ value: "gradient", label: "Gradient" }, { value: "accent", label: "Accent" }, { value: "none", label: "None" }]
        }
        EdSlider { path: "avatar.ringWidth"; label: "Ring width"; from: 1; to: 12; step: 1; decimals: 0; suffix: "px" }
        EdSwitch { path: "avatar.spin"; label: "Spinning ring" }
    }

    EdGroup {
        title: "Password field"
        EdChoice {
            path: "input.style"
            label: "Style"
            options: [{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }, { value: "underline", label: "Underline" }]
        }
        EdSlider { path: "input.width"; label: "Width"; from: 220; to: 560; step: 10; decimals: 0; suffix: "px" }
        EdSlider { path: "input.height"; label: "Height"; from: 36; to: 72; step: 2; decimals: 0; suffix: "px" }
        EdSlider { path: "input.radius"; label: "Corners"; from: 0; to: 36; step: 1; decimals: 0; suffix: "px" }
        EdText { path: "input.placeholder"; label: "Placeholder" }
        EdChoice {
            path: "input.mask"
            label: "Dots"
            options: [{ value: "●", label: "●" }, { value: "•", label: "•" }, { value: "✱", label: "✱" }, { value: "◆", label: "◆" }, { value: "♥", label: "♥" }]
        }
    }
}
