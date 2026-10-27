pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common

// Power actions (logind lets the active seat's greeter do these) and battery.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int percent: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: !UPower.onBattery
    readonly property string icon: {
        if (!hasBattery)
            return "power_plug";
        const step = Math.max(1, Math.min(9, Math.round(percent / 10)));
        if (charging)
            return percent >= 98 ? "battery_charging_100" : "battery_charging_" + step * 10;
        return percent >= 98 ? "battery" : percent < 8 ? "battery_alert" : "battery_" + step * 10;
    }

    readonly property var actions: [
        { id: "suspend", icon: "power_sleep", label: "Sleep", enabled: Config.power.suspend },
        { id: "hibernate", icon: "snowflake", label: "Hibernate", enabled: Config.power.hibernate },
        { id: "reboot", icon: "restart", label: "Restart", enabled: Config.power.reboot },
        { id: "poweroff", icon: "power", label: "Shut down", enabled: Config.power.poweroff }
    ].filter(a => a.enabled)

    signal simulated(string action)

    function run(action) {
        // never power anything off from the test window or the editor
        if (!Config.greeter) {
            simulated(action);
            return;
        }
        Quickshell.execDetached(["systemctl", action]);
    }
}
