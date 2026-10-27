pragma Singleton

import QtQuick
import Quickshell

// "Someone is here": typing or moving the mouse anywhere wakes every screen
// out of ambient mode. Also how the user menu asks the login box for a name.
Singleton {
    signal poked
    signal otherUserRequested

    function poke() {
        poked();
    }
}
