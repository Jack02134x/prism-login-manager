pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Sleep / restart / shut down. The first click arms a button (it turns red and
// says what it'll do); a second click within 3 s does it.
RowLayout {
    id: root

    property real size: 42
    property string armed: ""

    visible: Theme.show.power && Power.actions.length > 0
    spacing: 10

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Repeater {
        model: Power.actions
        delegate: IconBtn {
            id: btn
            required property var modelData
            size: root.size
            icon: modelData.icon
            active: root.armed === modelData.id
            accent: Theme.error
            tooltip: active ? "Click again to " + modelData.label.toLowerCase() : modelData.label
            onClicked: {
                Activity.poke();
                if (root.armed === modelData.id) {
                    root.armed = "";
                    Power.run(modelData.id);
                } else {
                    root.armed = modelData.id;
                    disarm.restart();
                }
            }
        }
    }
}
