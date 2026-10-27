import QtQuick
import QtQuick.Layouts
import qs.common

// Particles, overlays, and how the screen comes and goes.
ColumnLayout {
    spacing: 14

    EdGroup {
        title: "Atmosphere"
        EdChoice {
            path: "effects.particles"
            label: "Particles"
            options: [{ value: "none", label: "None" }, { value: "snow", label: "Snow" }, { value: "fireflies", label: "Fireflies" }, { value: "stars", label: "Stars" }, { value: "embers", label: "Embers" }, { value: "rain", label: "Rain" }]
        }
        EdSlider { visible: Theme.fx.particles !== "none"; path: "effects.particleCount"; label: "How many"; from: 10; to: 400; step: 5; decimals: 0 }
        EdSlider { path: "effects.aurora"; label: "Aurora"; percent: true; hint: "light ribbons over everything" }
        EdSlider { path: "effects.vignette"; label: "Vignette"; percent: true }
        EdSlider { path: "effects.grain"; label: "Film grain"; from: 0; to: 0.5; percent: true }
        EdSwitch { path: "effects.glow"; label: "Glow"; hint: "behind the avatar and cards" }
    }

    EdGroup {
        title: "Motion"
        EdChoice {
            path: "effects.intro"
            label: "Appear"
            options: [{ value: "rise", label: "Rise" }, { value: "zoom", label: "Zoom" }, { value: "fade", label: "Fade" }, { value: "blur", label: "Unblur" }, { value: "none", label: "None" }]
        }
        EdSlider { path: "effects.introMs"; label: "Appear time"; from: 200; to: 3000; step: 50; decimals: 0; suffix: "ms" }
        EdChoice {
            path: "effects.outro"
            label: "Log in"
            options: [{ value: "zoom", label: "Zoom away" }, { value: "fade", label: "Fade" }, { value: "none", label: "Instant" }]
        }
        EdSlider { path: "effects.ambientAfter"; label: "Ambient after"; from: -1; to: 300; step: 5; decimals: 0; suffix: "s"; hint: "-1 = plm.json's setting, 0 = never" }
    }
}
