pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.common
import qs.greeter
import qs.services
import qs.widgets

// The theme editor: sections on the left, the real login screen on the right,
// updating as you change things. Bundled and installed themes are read-only;
// saving one makes your own copy. "Use for login" installs it system-wide.
FloatingWindow {
    id: win

    title: "PLM Theme Editor"
    implicitWidth: 1580
    implicitHeight: 960
    color: Ed.bg

    // absolute, for pkexec: set by `plm editor`; else the repo's copy or the installed one
    readonly property string plmBin: Config.env("PLM_BIN", Config.dataDir.endsWith("/share/plm") ? Config.dataDir.replace(/\/share\/plm$/, "/bin/plm") : Config.dataDir + "/bin/plm")
    readonly property bool writable: Themes.isWritable(Theme.dir)
    readonly property var current: Themes.list.find(t => t.dir === Theme.dir) ?? null
    property string page: Config.env("PLM_EDITOR_PAGE", "background")
    property string aspect: "16:9"
    property bool ambient: false
    // what to do once a save finishes: "" | "install" | "test"
    property string afterSave: ""
    property string pendingOpen: ""
    property bool confirmDiscard: false

    readonly property var pages: [
        { id: "theme", icon: "palette", label: "Theme" },
        { id: "layout", icon: "view_dashboard", label: "Layout" },
        { id: "background", icon: "wallpaper", label: "Background" },
        { id: "colors", icon: "eyedropper", label: "Colours" },
        { id: "type", icon: "format_font", label: "Clock & type" },
        { id: "login", icon: "account_circle", label: "Login" },
        { id: "effects", icon: "creation", label: "Effects" }
    ]

    // ---- actions ----
    function toast(t, bad) {
        toastBox.text = t;
        toastBox.bad = bad === true;
        toastBox.shown = true;
        toastTimer.restart();
    }
    function uniqueDir(name) {
        const base = Utils.slug(name);
        let id = base;
        for (let i = 2; Themes.list.some(t => t.user && t.id === id); i++)
            id = base + "-" + i;
        return Config.userThemeDir + "/" + id;
    }
    function save(then) {
        afterSave = then ?? "";
        if (writable) {
            Themes.save(Theme.dir, "");
        } else {
            const name = Theme.data.name + (current?.bundled || current?.system ? " (mine)" : "");
            saveAs(name);
        }
    }
    function saveAs(name) {
        const dir = uniqueDir(name);
        Theme.set("name", name);
        pendingOpen = dir;
        Themes.save(dir, Theme.dir);
    }
    function openTheme(dir) {
        if (Theme.dirty && !confirmDiscard && dir !== Theme.dir) {
            confirmDiscard = true;
            discardTimer.restart();
            toast("Unsaved changes: click the theme again to discard them", true);
            return;
        }
        confirmDiscard = false;
        Themes.wanted = dir;
        if (dir === Theme.dir)
            Themes.refresh();
    }
    function runAfterSave() {
        const what = afterSave;
        afterSave = "";
        if (what === "install")
            install();
        else if (what === "test")
            testIt();
    }
    function install() {
        if (Theme.dirty)
            return save("install");
        installProc.command = ["pkexec", plmBin, "theme", "install", Theme.dir, "--activate"];
        installProc.running = true;
        toast("Asking for your password to install " + Theme.data.name + "…");
    }
    function testIt() {
        if (Theme.dirty)
            return save("test");
        Quickshell.execDetached([plmBin, "test", "--theme", Theme.dir, "--fullscreen"]);
    }

    Timer {
        id: discardTimer
        interval: 4000
        onTriggered: win.confirmDiscard = false
    }

    Connections {
        target: Themes
        function onSaved(dir) {
            win.toast("Saved to " + dir.replace(Config.home, "~"));
            if (win.pendingOpen !== "") {
                Themes.wanted = win.pendingOpen;
                win.pendingOpen = "";
                // the new copy loads first, then whatever was waiting runs
                followUp.restart();
            } else {
                win.runAfterSave();
            }
        }
        function onSaveFailed(message) {
            win.afterSave = "";
            win.toast(message, true);
        }
    }
    Timer {
        id: followUp
        interval: 700
        onTriggered: win.runAfterSave()
    }

    Process {
        id: installProc
        stderr: StdioCollector { id: installErr }
        onExited: code => {
            if (code === 0) {
                win.toast(Theme.data.name + " is now the login screen");
                Themes.refresh();
            } else if (code === 126 || code === 127) {
                win.toast("Not installed: the password prompt was cancelled", true);
            } else {
                win.toast("Install failed: " + installErr.text.trim().split("\n").pop(), true);
            }
        }
    }
    Process {
        id: syncProc
        property var extra: []
        command: [win.plmBin, "sync"].concat(extra)
        stdout: StdioCollector { id: syncOut }
        stderr: StdioCollector { id: syncErr }
        onExited: code => {
            const lines = syncOut.text.split("\n").filter(l => l.trim() !== "");
            const line = lines.find(l => l.startsWith("wallpaper:")) ?? lines[0] ?? "done";
            win.toast(code === 0 ? line.replace(Config.home, "~") : "Sync failed: " + syncErr.text.trim().replace(/^plm: /, ""), code !== 0);
        }
    }

    Shortcut {
        sequences: [StandardKey.Save]
        onActivated: win.save()
    }
    Shortcut {
        sequences: [StandardKey.Undo]
        onActivated: Theme.undo()
    }
    Shortcut {
        sequences: [StandardKey.Redo, "Ctrl+Y"]
        onActivated: Theme.redo()
    }

    // PLM_SCREENSHOT works here too (docs)
    Timer {
        running: Config.screenshot !== ""
        interval: Config.screenshotDelay
        onTriggered: main.grabToImage(r => {
            r.saveToFile(Config.screenshot);
            Qt.quit();
        })
    }

    // ---- layout ----
    // PLM_SCREENSHOT_SIZE renders the editor at a fixed size (for docs)
    readonly property var shotSize: Config.env("PLM_SCREENSHOT_SIZE", "").split("x").map(Number)

    Rectangle {
        id: main
        width: win.shotSize.length === 2 && win.shotSize[0] > 0 ? win.shotSize[0] : parent.width
        height: win.shotSize.length === 2 && win.shotSize[0] > 0 ? win.shotSize[1] : parent.height
        color: Ed.bg

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // top bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: Ed.panel
            border.width: 1
            border.color: Ed.stroke

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 10

                // logo: a little prism of the theme's colours
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 10
                    rotation: 45
                    scale: 0.8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accent1 }
                        GradientStop { position: 0.5; color: Theme.accent2 }
                        GradientStop { position: 1; color: Theme.accent3 }
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Prism Login Manager"
                        color: Ed.text
                        font.family: Ed.font
                        font.pixelSize: 15
                        font.weight: Font.Black
                    }
                    Text {
                        text: "Theme editor"
                        color: Ed.faint
                        font.family: Ed.font
                        font.pixelSize: 11
                    }
                }

                Item { Layout.preferredWidth: 18 }

                // the open theme
                RowLayout {
                    spacing: 8
                    Text {
                        text: Theme.data.name
                        color: Ed.text
                        font.family: Ed.font
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        implicitWidth: whereText.implicitWidth + 14
                        implicitHeight: 20
                        radius: 6
                        color: Ed.field
                        Text {
                            id: whereText
                            anchors.centerIn: parent
                            text: win.writable ? "yours" : win.current?.system ? "installed · read-only" : "bundled · read-only"
                            color: Ed.dim
                            font.family: Ed.font
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }
                    Rectangle {
                        visible: Theme.dirty
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: Ed.accent
                        EdTip {
                            text: "Unsaved changes"
                            show: dirtyHover.hovered
                        }
                        HoverHandler { id: dirtyHover }
                    }
                }

                Item { Layout.fillWidth: true }

                EdButton {
                    icon: "undo"
                    tooltip: "Undo (Ctrl+Z)"
                    enabled: Theme.history.length > 0
                    onClicked: Theme.undo()
                }
                EdButton {
                    icon: "redo"
                    tooltip: "Redo (Ctrl+Shift+Z)"
                    enabled: Theme.future.length > 0
                    onClicked: Theme.redo()
                }
                EdButton {
                    icon: "refresh"
                    tooltip: "Revert to the saved file"
                    enabled: Theme.dirty
                    onClicked: Themes.reload()
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Ed.stroke }

                // save as: an inline name box
                EdTextBox {
                    id: saveAsBox
                    visible: false
                    Layout.preferredWidth: 220
                    placeholder: "New theme name"
                    onCommitted: {
                        if (text.trim() !== "" && visible)
                            win.saveAs(text.trim());
                        visible = false;
                    }
                    Keys.onEscapePressed: visible = false
                }
                EdButton {
                    icon: "content_save_edit"
                    text: "Save as…"
                    onClicked: {
                        saveAsBox.text = Theme.data.name + " 2";
                        saveAsBox.visible = true;
                        saveAsBox.input.forceActiveFocus();
                        saveAsBox.input.selectAll();
                    }
                }
                EdButton {
                    icon: "content_save"
                    text: win.writable ? "Save" : "Save a copy"
                    tooltip: "Ctrl+S"
                    enabled: Theme.dirty || !win.writable
                    onClicked: win.save()
                }
                EdButton {
                    icon: "play"
                    text: "Test"
                    tooltip: "Full screen; Ctrl+Q to leave"
                    onClicked: win.testIt()
                }
                EdButton {
                    icon: "shield_lock"
                    text: "Use for login"
                    primary: true
                    tooltip: "Install system-wide and make it the login screen"
                    onClicked: win.install()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // navigation rail
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 88
                color: Ed.panel

                ColumnLayout {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 14
                    spacing: 6

                    Repeater {
                        model: win.pages
                        delegate: Item {
                            id: nav
                            required property var modelData
                            readonly property bool on: win.page === modelData.id
                            implicitWidth: 72
                            implicitHeight: 64
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                width: nav.on ? 56 : nma.containsMouse ? 48 : 40
                                height: 32
                                radius: 16
                                color: nav.on ? Qt.rgba(Ed.accent.r, Ed.accent.g, Ed.accent.b, 0.2) : nma.containsMouse ? Ed.field : "transparent"
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                Icon {
                                    anchors.centerIn: parent
                                    icon: nav.modelData.icon
                                    size: 19
                                    color: nav.on ? Ed.accent : Ed.dim
                                    bounce: false
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 40
                                text: nav.modelData.label
                                color: nav.on ? Ed.text : Ed.faint
                                font.family: Ed.font
                                font.pixelSize: 11
                                font.weight: nav.on ? Font.Bold : Font.Medium
                            }
                            MouseArea {
                                id: nma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.page = nav.modelData.id
                            }
                        }
                    }
                }
            }

            // controls
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Utils.clamp(main.width * 0.3, 400, 500)
                color: Ed.panel
                border.width: 1
                border.color: Ed.stroke

                Flickable {
                    id: flick
                    anchors.fill: parent
                    anchors.margins: 1
                    contentHeight: pageLoader.implicitHeight + 40
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Loader {
                        id: pageLoader
                        x: 18
                        y: 18
                        width: flick.width - 36
                        sourceComponent: ({
                            theme: themePage,
                            layout: layoutPage,
                            background: bgPage,
                            colors: colorsPage,
                            type: typePage,
                            login: loginPage,
                            effects: effectsPage
                        })[win.page]
                        onLoaded: flick.contentY = 0
                    }
                }
                Component { id: themePage; PageTheme { onOpen: dir => win.openTheme(dir) } }
                Component { id: layoutPage; PageLayout {} }
                Component { id: bgPage; PageBackground {
                    onSyncRequested: args => {
                        if (syncProc.running)
                            return;
                        syncProc.extra = args;
                        syncProc.running = true;
                    }
                } }
                Component { id: colorsPage; PageColors {} }
                Component { id: typePage; PageType {} }
                Component { id: loginPage; PageLogin {} }
                Component { id: effectsPage; PageEffects {} }
            }

            // preview
            Item {
                id: previewArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property size virt: ({
                    "16:9": Qt.size(1920, 1080),
                    "16:10": Qt.size(1920, 1200),
                    "21:9": Qt.size(2560, 1080),
                    "4:3": Qt.size(1600, 1200)
                })[win.aspect]
                // leave room under the frame for the simulation buttons (two rows when narrow)
                readonly property real fit: Math.min((width - 56) / virt.width, (height - (width < 900 ? 170 : 120)) / virt.height)

                ClippingRectangle {
                    id: frame
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    width: previewArea.virt.width * previewArea.fit
                    height: previewArea.virt.height * previewArea.fit
                    radius: 16
                    color: "black"
                    border.width: 1
                    border.color: Ed.stroke

                    Item {
                        width: previewArea.virt.width
                        height: previewArea.virt.height
                        scale: previewArea.fit
                        transformOrigin: Item.TopLeft

                        GreeterView {
                            id: preview
                            anchors.fill: parent
                            preview: true
                            forceAmbient: win.ambient
                        }
                    }
                }

                // simulate what the login screen goes through
                Flow {
                    anchors.top: frame.bottom
                    anchors.topMargin: 16
                    anchors.left: frame.left
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    spacing: 8

                    EdButton { icon: "replay"; text: "Intro"; onClicked: { win.ambient = false; Auth.simulate("reset"); preview.replayIntro(); } }
                    EdButton { icon: "close_octagon_outline"; text: "Wrong password"; onClicked: Auth.simulate("fail") }
                    EdButton { icon: "shield_key"; text: "2FA prompt"; onClicked: Auth.simulate("prompt") }
                    EdButton { icon: "loading"; text: "Checking"; onClicked: Auth.simulate("busy") }
                    EdButton { icon: "rocket_launch"; text: "Log in"; onClicked: Auth.simulate("launch") }
                    EdButton { icon: "weather_night"; text: "Ambient"; checked: win.ambient; onClicked: win.ambient = !win.ambient }
                    EdButton { icon: "keyboard_caps"; text: "Caps Lock"; checked: Keyboard.simulateCaps; onClicked: Keyboard.simulateCaps = !Keyboard.simulateCaps }
                    Rectangle { width: 1; height: 34; color: Ed.stroke }
                    Repeater {
                        model: ["16:9", "16:10", "21:9", "4:3"]
                        delegate: EdButton {
                            required property string modelData
                            text: modelData
                            checked: win.aspect === modelData
                            onClicked: win.aspect = modelData
                        }
                    }
                }
            }
        }
    }

    }

    // toast
    Rectangle {
        id: toastBox
        property string text: ""
        property bool bad: false
        property bool shown: false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: shown ? 24 : -height - 10
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
        width: Math.min(parent.width - 80, toastLabel.implicitWidth + 44)
        height: 44
        radius: 22
        color: "#000000"
        border.width: 1
        border.color: bad ? Ed.danger : Ed.accent
        z: 100
        Text {
            id: toastLabel
            anchors.centerIn: parent
            width: parent.width - 44
            horizontalAlignment: Text.AlignHCenter
            text: toastBox.text
            color: toastBox.bad ? Ed.danger : Ed.text
            elide: Text.ElideMiddle
            font.family: Ed.font
            font.pixelSize: 13
        }
        Timer {
            id: toastTimer
            interval: 4200
            onTriggered: toastBox.shown = false
        }
    }
}
