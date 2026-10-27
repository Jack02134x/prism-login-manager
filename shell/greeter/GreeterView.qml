pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.background
import qs.common
import qs.components
import qs.services
import qs.widgets

// Everything on one screen: background, effects, and (on the screen with the
// login) the theme's layout. Also used inside the editor's preview.
//
// Custom themes (layout "custom") get a `plm` object with the services and
// building blocks; see themes/terminal/Main.qml.
Item {
    id: view

    objectName: "plmView"

    property bool primary: true
    property bool preview: false
    // the editor's "ambient" switch
    property bool forceAmbient: false
    readonly property bool ambient: idle || forceAmbient
    property bool idle: false
    property real ambientT: ambient ? 1 : 0
    Behavior on ambientT { NumAnim { duration: 1400; easing.bezierCurve: Motion.emphasized } }

    readonly property real uiScale: {
        const down = Math.min(width / 1280, height / 860);
        if (down < 1)
            return Math.max(0.5, down);
        return height > 1300 ? Math.min(2, height / 1080) : 1;
    }

    // 0 -> 1 as the screen appears, back to 0 as the session starts
    property real reveal: 0
    readonly property bool leaving: Auth.phase === "launching"
    readonly property bool typing: layout.item?.typing ?? false
    readonly property string intro: Theme.fx.intro

    signal screenshotDone(string path)

    focus: true

    // ---- background ----
    Background {
        id: bg
        anchors.fill: parent
        playing: true
        extraBlur: {
            let b = 0;
            if (view.typing)
                b += Theme.bgFocusBlur * 0.6;
            b += view.ambientT * Theme.bgFocusBlur * 0.4;
            if (view.intro === "blur")
                b += 1 - view.reveal;
            return b;
        }
        px: hover.px
        py: hover.py
        scale: view.leaving && Theme.fx.outro === "zoom" ? 1.08 : 1
        Behavior on scale { NumAnim { duration: 900 } }
    }
    Particles {
        anchors.fill: parent
    }
    Overlay {
        anchors.fill: parent
    }

    // ---- the layout ----
    Item {
        id: stage
        anchors.fill: parent
        opacity: view.reveal
        scale: view.intro === "zoom" || (view.leaving && Theme.fx.outro === "zoom") ? 0.92 + 0.08 * view.reveal : 1
        transform: Translate {
            y: view.intro === "rise" ? (1 - view.reveal) * 50 : 0
        }

        // layouts are designed for about 1920×1080: shrink them on small (or heavily
        // scaled) screens so nothing overlaps, grow them on big unscaled ones
        Item {
            id: scaler
            width: parent.width / view.uiScale
            height: parent.height / view.uiScale
            scale: view.uiScale
            transformOrigin: Item.TopLeft

        Loader {
            id: layout
            anchors.fill: parent
            active: view.primary && Theme.ready
            // the editor's preview mustn't take the keyboard from its fields
            onLoaded: if (!view.preview) Qt.callLater(() => item?.focusField?.())
            onStatusChanged: if (status === Loader.Error) console.warn("PLM: layout failed to load:", view.layoutUrl)
        }

        // other monitors: the clock, and a hint that the login can move here
        Loader {
            anchors.centerIn: parent
            active: !view.primary && Theme.ready
            sourceComponent: Clock {
                size: Theme.clock.size * 0.7
            }
        }
        }
        Chip {
            visible: !view.primary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            icon: "cursor_default_click"
            text: "Click to log in on this screen"
            opacity: hover.containsMouse ? 1 : 0.5
        }
    }

    readonly property string layoutUrl: {
        const l = Theme.layout;
        if (l === "custom")
            return Theme.resolve(Theme.data.main);
        const known = { prism: "Prism", glass: "Glass", minimal: "Minimal", coverflow: "Coverflow" };
        return Qt.resolvedUrl("../layouts/" + (known[l] ?? "Prism") + "Layout.qml");
    }
    onLayoutUrlChanged: loadLayout()
    onPrimaryChanged: loadLayout()
    Component.onCompleted: {
        loadLayout();
        introAnim.start();
    }
    function loadLayout() {
        if (!primary || !Theme.ready)
            return;
        // built-in layouts take view + backdrop; custom ones get everything through `plm`
        layout.setSource(layoutUrl, Theme.layout === "custom" ? { plm: api } : { view: view, backdrop: bg });
    }
    Connections {
        target: Theme
        function onReadyChanged() {
            view.loadLayout();
        }
    }

    // ---- intro / outro ----
    NumberAnimation {
        id: introAnim
        target: view
        property: "reveal"
        from: 0
        to: 1
        duration: view.intro === "none" ? 1 : Theme.fx.introMs
        easing.type: Easing.OutCubic
    }
    function replayIntro() {
        introAnim.restart();
    }
    Connections {
        target: Auth
        function onLaunching() {
            outroAnim.restart();
        }
        function onPhaseChanged() {
            // test mode: back from the pretend launch
            if (Auth.phase === "idle" && view.reveal < 1 && !introAnim.running)
                introAnim.restart();
        }
    }
    NumberAnimation {
        id: outroAnim
        target: view
        property: "reveal"
        to: 0
        duration: 650
        easing.type: Easing.InCubic
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: view.leaving && Theme.fx.outro !== "none" ? 1 - view.reveal : 0
    }

    // ---- ambient (idle) ----
    Timer {
        id: idleTimer
        interval: Math.max(5, Theme.ambientAfter) * 1000
        running: Theme.ambientAfter > 0 && !view.idle && !view.preview && !view.leaving
        onTriggered: view.idle = true
    }
    function poke() {
        idle = false;
        idleTimer.restart();
    }
    Connections {
        target: Activity
        function onPoked() {
            view.poke();
        }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        property real px: 0.5
        property real py: 0.5
        property point last: Qt.point(-1, -1)
        onPositionChanged: mouse => {
            px = mouse.x / Math.max(1, width);
            py = mouse.y / Math.max(1, height);
            // ignore the jitter of a resting mouse
            if (Math.abs(mouse.x - last.x) + Math.abs(mouse.y - last.y) > 4) {
                last = Qt.point(mouse.x, mouse.y);
                Activity.poke();
            }
        }
        onClicked: {
            Activity.poke();
            if (!view.primary)
                view.activateRequested();
            else
                layout.item?.focusField?.();
        }
    }
    signal activateRequested

    Keys.onPressed: event => {
        Activity.poke();
        if (Config.test && event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
            Qt.quit();
            event.accepted = true;
        } else if (event.key === Qt.Key_F5 && !Config.greeter) {
            Themes.refresh();
            view.replayIntro();
            event.accepted = true;
        }
    }

    // ---- toasts (test mode / editor) ----
    Rectangle {
        id: toast
        property string text: ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: shown ? 28 : -height - 10
        property bool shown: false
        Behavior on anchors.topMargin { NumAnim { duration: Motion.slow; easing.bezierCurve: Motion.spatial } }
        width: Math.min(parent.width - 60, toastText.implicitWidth + 40)
        height: 44
        radius: 22
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Theme.alpha(Theme.accent1, 0.5)
        z: 2000
        Txt {
            id: toastText
            anchors.centerIn: parent
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            text: toast.text
            color: "white"
            font.pixelSize: 13
        }
        Timer {
            id: toastTimer
            interval: 3600
            onTriggered: toast.shown = false
        }
        function show(t) {
            text = t;
            shown = true;
            toastTimer.restart();
        }
    }
    function toastMessage(t) {
        if (primary)
            toast.show(t);
    }
    Connections {
        target: Auth
        function onSimulatedLaunch(summary) {
            view.toastMessage("Would start " + summary);
        }
    }
    Connections {
        target: Power
        function onSimulated(action) {
            view.toastMessage("Would run: systemctl " + action);
        }
    }
    Connections {
        target: Themes
        function onLoadErrorChanged() {
            if (Themes.loadError !== "")
                view.toastMessage(Themes.loadError);
        }
    }

    // ---- what custom themes get ----
    QtObject {
        id: api
        readonly property var auth: Auth
        readonly property var users: Users
        readonly property var sessions: Sessions
        readonly property var theme: Theme
        readonly property var power: Power
        readonly property var keyboard: Keyboard
        readonly property var config: Config
        readonly property var sync: Sync
        readonly property var utils: Utils
        readonly property var activity: Activity
        readonly property Item view: view
        readonly property Item backdrop: bg

        readonly property Component clock: Component { Clock {} }
        readonly property Component loginBox: Component { LoginBox {} }
        readonly property Component userMenu: Component { UserMenu {} }
        readonly property Component sessionMenu: Component { SessionMenu {} }
        readonly property Component powerButtons: Component { PowerButtons {} }
        readonly property Component statusChips: Component { StatusChips {} }
        readonly property Component avatar: Component { Avatar {} }
        readonly property Component inputField: Component { InputField {} }
        readonly property Component glass: Component { Glass {} }
        readonly property Component chip: Component { Chip {} }
        readonly property Component icon: Component { Icon {} }
        readonly property Component text: Component { Txt {} }
    }

    // ---- PLM_SCREENSHOT: grab the screen and quit (docs, CI, theme previews) ----
    Timer {
        running: Config.screenshot !== "" && view.primary && !view.preview
        interval: Config.screenshotDelay
        onTriggered: view.grabToImage(r => {
            r.saveToFile(Config.screenshot);
            console.info("PLM: saved", Config.screenshot);
            Qt.quit();
        })
    }
}
