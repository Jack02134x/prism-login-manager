pragma Singleton

import QtQuick
import Quickshell
import qs.common

// Which monitor shows the login box: plm.json's `monitor`, else the first one.
// Clicking another monitor moves it there.
Singleton {
    id: root

    property string active: ""

    function isPrimary(screen) {
        const name = screen?.name ?? "";
        if (active !== "")
            return name === active;
        const all = Quickshell.screens;
        if (Config.monitor !== "" && all.some(s => s.name === Config.monitor))
            return name === Config.monitor;
        return all.length === 0 || all[0].name === name;
    }
    function activate(screen) {
        active = screen?.name ?? "";
    }
}
