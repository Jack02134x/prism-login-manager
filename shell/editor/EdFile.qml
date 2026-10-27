pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.common
import qs.widgets

// A file in the theme (a wallpaper, a video, a poster frame): type a path,
// browse for one, or pick from the wallpaper gallery. With no `path` it only
// reports the choice (picked) and shows `fileValue`.
ColumnLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    // media | image
    property string accept: "media"
    readonly property bool bound: path !== ""
    property string fileValue: ""
    readonly property string value: bound ? String(Theme.get(path) ?? "") : fileValue

    signal picked(string file)

    function choose(file) {
        if (bound)
            Theme.set(path, file);
        else
            picked(file);
    }
    property bool galleryOpen: false

    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        EdLabel {
            text: root.label
            hint: root.hint
        }
        EdTextBox {
            id: box
            Layout.fillWidth: true
            mono: true
            placeholder: "none"
            text: root.value
            onCommitted: if (text.trim() !== root.value) root.choose(text.trim())
        }
        EdButton {
            icon: "folder_open"
            tooltip: "Browse…"
            onClicked: picker.running = true
        }
        EdButton {
            icon: "image_multiple"
            tooltip: "Gallery"
            checked: root.galleryOpen
            onClicked: {
                root.galleryOpen = !root.galleryOpen;
                if (root.galleryOpen)
                    Gallery.load();
            }
        }
        EdButton {
            visible: root.bound && root.value !== ""
            icon: "close"
            tooltip: "Clear"
            onClicked: Theme.set(root.path, "")
        }
    }
    onValueChanged: if (!box.input.activeFocus) box.text = value

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Pick a " + (root.accept === "image" ? "picture" : "wallpaper (picture, GIF or video)"),
            "--file-filter=" + (root.accept === "image" ? "Pictures | *.png *.jpg *.jpeg *.webp" : "Wallpapers | *.png *.jpg *.jpeg *.webp *.gif *.mp4 *.webm *.mkv *.mov"), "--file-filter=All files | *"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    root.choose(p);
            }
        }
        onExited: code => {
            if (code === 127 || code === 255)
                box.placeholder = "zenity isn't installed: type a path";
        }
    }

    Rectangle {
        visible: root.galleryOpen
        Layout.fillWidth: true
        Layout.preferredHeight: 300
        radius: Ed.radius
        color: Ed.bg
        clip: true

        Text {
            anchors.centerIn: parent
            visible: Gallery.loaded && grid.count === 0
            text: "No wallpapers found in\n" + Gallery.dirs.slice(0, 3).join("\n")
            horizontalAlignment: Text.AlignHCenter
            color: Ed.faint
            font.family: Ed.font
            font.pixelSize: 12
        }

        GridView {
            id: grid
            anchors.fill: parent
            anchors.margins: 6
            cellWidth: width / 3
            cellHeight: cellWidth * 0.62
            model: Gallery.items.filter(i => root.accept === "media" || i.kind === "image")
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: cell
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight
                readonly property bool on: root.value === modelData.path

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: Ed.field
                    border.width: cell.on ? 2 : 0
                    border.color: Ed.accent
                    Image {
                        anchors.fill: parent
                        source: Gallery.thumbsVersion >= 0 ? cell.modelData.thumb : ""
                        sourceSize.width: 240
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Rectangle {
                        visible: cell.modelData.kind !== "image"
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        width: 22
                        height: 22
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.6)
                        Icon {
                            anchors.centerIn: parent
                            icon: cell.modelData.kind === "video" ? "play" : "filmstrip"
                            size: 13
                            color: "white"
                            bounce: false
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(cell.modelData.path)
                        EdTip {
                            text: Utils.fileName(cell.modelData.path)
                            show: parent.containsMouse
                            anchors.top: undefined
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                        }
                    }
                }
            }
        }
    }
}
