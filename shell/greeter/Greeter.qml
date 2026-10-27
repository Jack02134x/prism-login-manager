pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// The login screen's windows: a full-screen layer surface on every monitor
// (the login box on one of them), or one normal window for test mode / cage.
Scope {
    Variants {
        model: Config.windowed ? [] : Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property bool primary: Screens.isPrimary(modelData)

            screen: modelData
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "plm"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            GreeterView {
                anchors.fill: parent
                primary: win.primary
                onActivateRequested: Screens.activate(win.modelData)
            }
        }
    }

    LazyLoader {
        active: Config.windowed

        FloatingWindow {
            id: floating
            title: Config.greeter ? "PLM" : "PLM · test mode"
            implicitWidth: 1600
            implicitHeight: 900
            color: "black"

            // PLM_SCREENSHOT_SIZE=1920x1080: render at that size (scaled to fit), for docs
            readonly property var shotSize: Config.env("PLM_SCREENSHOT_SIZE", "").split("x").map(Number)
            readonly property bool fixed: shotSize.length === 2 && shotSize[0] > 0

            Item {
                anchors.fill: parent
                GreeterView {
                    width: floating.fixed ? floating.shotSize[0] : parent.width
                    height: floating.fixed ? floating.shotSize[1] : parent.height
                    scale: floating.fixed ? Math.min(parent.width / width, parent.height / height) : 1
                    transformOrigin: Item.TopLeft
                    primary: true
                }
            }
        }
    }
}
