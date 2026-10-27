pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// A colour in the theme: a swatch and hex box; the swatch opens a picker with
// a saturation/value square, a hue strip, and quick picks from the live palette.
ColumnLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    readonly property string value: String(Theme.get(path) ?? "#000000")
    readonly property color current: Qt.color(value)
    property bool open: false

    property real h: 0
    property real s: 0
    property real v: 0
    function syncHsv() {
        h = Math.max(0, current.hsvHue);
        s = current.hsvSaturation;
        v = current.hsvValue;
    }
    function write(live) {
        const hex = Theme.hex(Qt.hsva(h, s, v, 1));
        if (live) {
            Theme.data = Utils.withPath(Theme.data, path, hex);
            Theme.dirty = true;
        } else {
            Theme.set(path, hex);
        }
    }

    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        EdLabel {
            text: root.label
            hint: root.hint
        }
        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 10
            color: root.current
            border.width: 2
            border.color: root.open ? Ed.accent : Qt.rgba(1, 1, 1, 0.15)
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.syncHsv();
                    root.open = !root.open;
                }
            }
        }
        EdTextBox {
            id: hexBox
            Layout.fillWidth: true
            mono: true
            text: root.value
            onCommitted: {
                const t = text.trim();
                if (/^#?[0-9a-fA-F]{6}$/.test(t))
                    Theme.set(root.path, (t.startsWith("#") ? t : "#" + t).toLowerCase());
                else
                    text = root.value;
            }
        }
    }
    onValueChanged: if (!hexBox.input.activeFocus) hexBox.text = value

    RowLayout {
        visible: root.open
        Layout.fillWidth: true
        Layout.preferredHeight: 170
        spacing: 10

        // saturation (x) / value (y)
        Rectangle {
            id: sv
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Qt.hsva(root.h, 1, 1, 1)
            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }
            Rectangle {
                x: root.s * sv.width - 8
                y: (1 - root.v) * sv.height - 8
                width: 16
                height: 16
                radius: 8
                color: root.current
                border.width: 3
                border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function pick(mx, my, live) {
                    root.s = Utils.clamp(mx / width, 0, 1);
                    root.v = 1 - Utils.clamp(my / height, 0, 1);
                    root.write(live);
                }
                onPressed: mouse => pick(mouse.x, mouse.y, false)
                onPositionChanged: mouse => { if (pressed) pick(mouse.x, mouse.y, true); }
            }
        }

        // hue
        Rectangle {
            id: hue
            Layout.preferredWidth: 18
            Layout.fillHeight: true
            radius: 9
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ff0000" }
                GradientStop { position: 0.17; color: "#ffff00" }
                GradientStop { position: 0.33; color: "#00ff00" }
                GradientStop { position: 0.5; color: "#00ffff" }
                GradientStop { position: 0.67; color: "#0000ff" }
                GradientStop { position: 0.83; color: "#ff00ff" }
                GradientStop { position: 1.0; color: "#ff0000" }
            }
            Rectangle {
                y: root.h * hue.height - 4
                x: -3
                width: hue.width + 6
                height: 8
                radius: 4
                color: "transparent"
                border.width: 3
                border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function pick(my, live) {
                    root.h = Utils.clamp(my / height, 0, 0.999);
                    if (root.s < 0.05)
                        root.s = 0.6;
                    if (root.v < 0.05)
                        root.v = 0.8;
                    root.write(live);
                }
                onPressed: mouse => pick(mouse.y, false)
                onPositionChanged: mouse => { if (pressed) pick(mouse.y, true); }
            }
        }
    }

    // quick picks: what the theme resolves to right now, the synced Prism palette, basics
    Flow {
        visible: root.open
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: {
                const out = [Theme.hex(Theme.accent1), Theme.hex(Theme.accent2), Theme.hex(Theme.accent3)];
                for (const c of Theme.wallColors.slice(0, 5))
                    out.push(Theme.hex(c));
                for (const c of (Sync.palette?.accents ?? []).slice(0, 6))
                    out.push(c);
                out.push("#ffffff", "#d8dbe5", "#000000", "#0d0f14", "#ff8a80");
                return out.filter((c, i) => out.indexOf(c) === i);
            }
            delegate: Rectangle {
                required property string modelData
                width: 24
                height: 24
                radius: 7
                color: modelData
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Theme.set(root.path, parent.modelData);
                        root.syncHsv();
                    }
                }
            }
        }
    }
}
