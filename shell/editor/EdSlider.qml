import QtQuick
import QtQuick.Layouts
import qs.common

// A number in the theme, as a slider with its value.
RowLayout {
    id: root

    property string path: ""
    property string label: ""
    property string hint: ""
    property real from: 0
    property real to: 1
    property real step: 0.01
    property int decimals: 2
    property string suffix: ""
    // show 0..1 as 0..100%
    property bool percent: false
    readonly property real value: Number(Theme.get(path) ?? from)

    Layout.fillWidth: true
    spacing: 12

    EdLabel {
        text: root.label
        hint: root.hint
    }

    Item {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        readonly property real frac: Utils.clamp((root.value - root.from) / (root.to - root.from), 0, 1)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Ed.field
            Rectangle {
                width: parent.width * track.frac
                height: parent.height
                radius: 3
                color: Ed.accent
            }
        }
        Rectangle {
            x: (track.width - width) * track.frac
            anchors.verticalCenter: parent.verticalCenter
            width: ma.pressed ? 20 : 16
            height: width
            radius: width / 2
            color: Ed.text
            border.width: 3
            border.color: Ed.accent
            Behavior on width { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function at(x) {
                const f = Utils.clamp(x / width, 0, 1);
                let v = root.from + f * (root.to - root.from);
                v = Math.round(v / root.step) * root.step;
                return Number(v.toFixed(root.decimals));
            }
            // one undo step per drag: set() records it, the moves after it don't
            onPressed: mouse => {
                Theme.set(root.path, at(mouse.x));
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                Theme.data = Utils.withPath(Theme.data, root.path, at(mouse.x));
                Theme.dirty = true;
            }
            onWheel: wheel => {
                const d = wheel.angleDelta.y > 0 ? root.step : -root.step;
                Theme.set(root.path, Number(Utils.clamp(root.value + d * (root.to - root.from > 10 ? 1 : 2), root.from, root.to).toFixed(root.decimals)));
            }
        }
    }

    Text {
        Layout.preferredWidth: 52
        horizontalAlignment: Text.AlignRight
        text: root.percent ? Math.round(root.value * 100) + "%" : root.value.toFixed(root.step >= 1 ? 0 : root.decimals) + root.suffix
        color: Ed.dim
        font.family: Ed.mono
        font.pixelSize: 12
    }
}
