// Prism Login Manager (PLM): a greetd greeter, its test mode, and its theme editor.
// PLM_MODE picks which: greeter (default) | test | editor. See README.md.

import QtQuick
import Quickshell
import qs.common
import qs.editor
import qs.greeter
import qs.services

ShellRoot {
    LazyLoader {
        active: !Config.editor
        Greeter {}
    }
    LazyLoader {
        active: Config.editor
        Editor {}
    }

    // start the services nothing on screen touches right away
    Component.onCompleted: {
        Themes.loaded;
        Auth.ready;
        Keyboard.capsLock;
    }
}
