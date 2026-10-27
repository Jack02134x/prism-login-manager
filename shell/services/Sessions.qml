pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Desktop sessions from /usr/share/{wayland-sessions,xsessions}, plus extras
// from plm.json. X11 sessions are started through startx.
Singleton {
    id: root

    property var found: []
    property bool loaded: false

    readonly property var list: {
        const hidden = Array.from(Config.sessions.hidden ?? []);
        const out = found.filter(s => !hidden.includes(s.id));
        for (const e of (Config.sessions.extra ?? []))
            if (e && e.exec)
                out.push({ type: e.type ?? "wayland", id: "extra-" + Utils.slug(e.name ?? e.exec), name: e.name ?? e.exec, comment: e.comment ?? "", exec: e.exec, desktop: e.desktop ?? "" });
        if (Config.sessions.shell)
            out.push({ type: "shell", id: "shell", name: "Console", comment: "Your login shell, no desktop", exec: "", desktop: "" });
        return out;
    }

    function find(id) {
        return list.find(s => s.id === id) ?? null;
    }
    function icon(s) {
        if (!s)
            return "monitor";
        if (s.type === "shell")
            return "console";
        const n = (s.id + " " + s.name).toLowerCase();
        if (n.includes("hypr"))
            return "linux-hyprland";
        if (n.includes("plasma") || n.includes("kde"))
            return "linux-kde";
        if (n.includes("gnome"))
            return "linux-gnome";
        if (n.includes("xfce"))
            return "linux-xfce";
        if (n.includes("sway") || n.includes("niri") || n.includes("river"))
            return "view_quilt";
        return s.type === "x11" ? "monitor_shimmer" : "monitor";
    }

    // argv + environment for greetd
    function command(s, user) {
        if (!s)
            return null;
        const env = Array.from(Config.sessionEnv ?? []);
        if (s.type === "shell")
            return { argv: [Users.shellOf(user)], env: env };
        const argv = Utils.splitExec(s.exec);
        const desk = s.desktop !== "" ? s.desktop : s.name;
        env.push("XDG_SESSION_DESKTOP=" + s.id, "XDG_CURRENT_DESKTOP=" + desk, "DESKTOP_SESSION=" + s.id);
        if (s.type === "x11") {
            env.push("XDG_SESSION_TYPE=x11");
            return { argv: ["startx", "/usr/bin/env"].concat(argv), env: env };
        }
        env.push("XDG_SESSION_TYPE=wayland");
        return { argv: argv, env: env };
    }

    Process {
        running: true
        command: [Config.helper, "sessions"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.found = text.split("\n").filter(l => l.length > 0).map(l => {
                    const [type, id, name, comment, exec, desktop] = l.split("\t");
                    return { type, id, name, comment: comment ?? "", exec, desktop: desktop ?? "" };
                });
                root.loaded = true;
            }
        }
    }
}
