import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// What's behind everything: a picture, a GIF, a live video, the user's own
// Prism desktop, an animated shader, a gradient or a colour.
ColumnLayout {
    id: root

    readonly property string type: Theme.bg.type
    // runs `plm sync` with these arguments
    signal syncRequested(var args)

    spacing: 14

    EdGroup {
        title: "Background"
        EdChoice {
            path: "background.type"
            options: [
                { value: "media", label: "Picture / video", icon: "image" },
                { value: "prism", label: "Your desktop", icon: "monitor" },
                { value: "shader", label: "Animated", icon: "creation" },
                { value: "gradient", label: "Gradient", icon: "gradient_horizontal" },
                { value: "color", label: "Colour", icon: "format_color_fill" }
            ]
        }
    }

    EdGroup {
        visible: root.type === "prism"
        title: "Your desktop"
        note: {
            const who = "<b>" + Auth.user + "</b>";
            const now = Sync.available ? "Showing " + who + "'s " + (Sync.info?.source === "prism" ? "Prism " : "") + Sync.kind + ". " : "Nothing set for " + who + " yet, so the theme's own picture or animation shows. ";
            const how = Gallery.hasPrism ? "Sync copies your Prism wallpaper (live ones too), colours and avatar." : "Pick a picture, GIF or video for your login screen.";
            return now + how + " Everyone sees their own once they're picked at the login screen.";
        }

        // with Prism: follow its wallpaper
        RowLayout {
            visible: Gallery.hasPrism
            spacing: 8
            EdButton {
                icon: "sync"
                text: "Sync now"
                primary: true
                onClicked: root.syncRequested([])
            }
            EdButton {
                icon: "creation"
                text: "Follow Prism automatically"
                onClicked: root.syncRequested(["--auto"])
            }
        }

        // without Prism: choose one
        EdFile {
            visible: !Gallery.hasPrism
            label: "My wallpaper"
            hint: "copied for the login screen"
            fileValue: Sync.info?.source === "manual" ? (Sync.info?.origin?.wallpaper ?? "").split("|")[0] : ""
            onPicked: file => {
                if (file !== "")
                    root.syncRequested(["--wallpaper", file]);
            }
        }
    }

    EdGroup {
        visible: root.type === "media" || root.type === "prism"
        title: root.type === "prism" ? "Fallback picture" : "Picture, GIF or live video"
        EdFile { path: "background.source"; label: "File"; hint: "mp4 · webm · gif · png · jpg" }
        EdFile {
            visible: Utils.isVideo(Theme.bg.source)
            path: "background.fallback"
            label: "Poster"
            hint: "shown while the video starts"
            accept: "image"
        }
        EdChoice {
            path: "background.fill"
            label: "Fit"
            options: [{ value: "crop", label: "Fill" }, { value: "fit", label: "Fit" }, { value: "stretch", label: "Stretch" }]
        }
        EdSlider {
            visible: Theme.bgKind !== "image"
            path: "background.speed"
            label: "Speed"
            from: 0.25
            to: 2
            step: 0.05
            suffix: "×"
        }
    }

    EdGroup {
        visible: root.type === "shader" || (root.type === "prism" && Theme.bgType === "shader")
        title: "Animation"
        EdChoice {
            path: "background.shader"
            label: "Style"
            options: [{ value: "prism", label: "Light beams" }, { value: "aurora", label: "Aurora" }, { value: "mesh", label: "Mesh gradient" }]
        }
        EdSlider { path: "background.speed"; label: "Speed"; from: 1; to: 4; step: 1; decimals: 0; suffix: "×" }
        EdColor { path: "background.colors.0"; label: "Base" }
    }

    EdGroup {
        visible: root.type === "gradient" || root.type === "color"
        title: root.type === "color" ? "Colour" : "Gradient"
        EdColor { path: "background.colors.0"; label: root.type === "color" ? "Colour" : "Start" }
        EdColor { visible: root.type === "gradient"; path: "background.colors.1"; label: "Middle" }
        EdColor { visible: root.type === "gradient"; path: "background.colors.2"; label: "End" }
        EdSlider { visible: root.type === "gradient"; path: "background.angle"; label: "Angle"; from: 0; to: 360; step: 5; decimals: 0; suffix: "°" }
    }

    EdGroup {
        title: "Look"
        EdSlider { path: "background.blur"; label: "Blur"; percent: true; hint: Theme.bgType === "shader" ? "pictures only" : "" }
        EdSlider { path: "background.dim"; label: "Darken"; percent: true }
        EdSlider { path: "background.saturation"; label: "Saturation"; from: -1; to: 1; step: 0.05 }
        EdSlider { path: "background.zoom"; label: "Zoom"; from: 1; to: 1.4; step: 0.01; suffix: "×" }
        EdSlider { path: "background.parallax"; label: "Parallax"; percent: true; hint: "follows the mouse" }
        EdSlider { path: "background.focusBlur"; label: "Typing blur"; percent: true; hint: "extra while typing / idle" }
    }
}
