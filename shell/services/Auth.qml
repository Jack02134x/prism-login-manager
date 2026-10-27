pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import qs.common

// Who is logging in, into what, and how far along it is.
//
// The password is typed before greetd asks for it: submit() opens a greetd
// session and answers the first prompt with it. Anything PAM asks after that
// (an OTP, a second factor) shows up as `prompt` and goes back via submit().
//
// Outside the real greeter (test mode, the editor) nothing reaches greetd:
// a mock accepts any password except "fail", and "2fa" asks for a code.
Singleton {
    id: root

    readonly property bool mock: !Config.greeter || !Greetd.available

    property string user: ""
    property string session: ""
    // idle | busy | prompt | launching
    property string phase: "idle"
    // PAM's question when it needs more than the password
    property string prompt: ""
    property bool echo: false
    property string info: ""
    property string error: ""
    property int failures: 0
    property var pending: null

    readonly property bool busy: phase === "busy" || phase === "launching"
    readonly property var sessionInfo: Sessions.find(session)

    // the theme's outro plays, then the session starts
    signal launching
    // test mode: what would have started
    signal simulatedLaunch(string summary)
    signal failed(string message)

    readonly property bool ready: Users.loaded && Sessions.loaded && Memory.loaded && Config.loaded
    onReadyChanged: if (ready) pickDefaults()

    function pickDefaults() {
        if (user === "") {
            const cands = [Config.remember ? Memory.lastUser : "", Config.defaultUser, Config.greeter ? "" : Config.userName, Users.names[0] ?? ""];
            user = cands.find(n => n && Users.find(n)) ?? "";
        }
        pickSession();
    }
    function pickSession() {
        const cands = [Config.remember ? Memory.sessionFor(user) : "", Config.defaultSession, Sessions.list[0]?.id ?? ""];
        session = cands.find(id => id && Sessions.find(id)) ?? "";
    }

    function selectUser(name) {
        name = String(name ?? "").trim();
        if (name === "" || name === user)
            return;
        cancel();
        user = name;
        error = "";
        info = "";
        failures = 0;
        pickSession();
    }
    function cycleUser(delta) {
        const n = Users.names;
        if (n.length < 2)
            return;
        const i = n.indexOf(user);
        selectUser(n[((i < 0 ? 0 : i) + delta + n.length) % n.length]);
    }
    function selectSession(id) {
        session = id;
    }
    function cycleSession(delta) {
        const l = Sessions.list;
        if (l.length < 2)
            return;
        const i = l.findIndex(s => s.id === session);
        session = l[((i < 0 ? 0 : i) + delta + l.length) % l.length].id;
    }

    function submit(text) {
        if (busy || user === "")
            return;
        error = "";
        if (phase === "prompt") {
            phase = "busy";
            respond(text);
            return;
        }
        if (!sessionInfo) {
            fail("No desktop session found");
            return;
        }
        pending = text;
        phase = "busy";
        if (mock)
            mockStep.start();
        else
            Greetd.createSession(user);
    }

    function cancel() {
        mockStep.stop();
        if (!mock && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        pending = null;
        prompt = "";
        echo = false;
        if (phase !== "launching")
            phase = "idle";
    }

    function respond(text) {
        if (mock) {
            mockStep.start();
            return;
        }
        Greetd.respond(text);
    }

    function fail(message) {
        pending = null;
        prompt = "";
        echo = false;
        phase = "idle";
        failures++;
        error = message;
        failed(message);
    }

    function launch() {
        phase = "launching";
        prompt = "";
        Memory.remember(user, session);
        launching();
        outro.restart();
    }

    Timer {
        id: outro
        interval: Theme.fx.outro === "none" ? 60 : 750
        onTriggered: {
            const cmd = Sessions.command(root.sessionInfo, root.user);
            if (root.mock) {
                root.simulatedLaunch((root.sessionInfo?.name ?? "?") + " as " + root.user + ": " + cmd.argv.join(" "));
                backToIdle.restart();
            } else {
                Greetd.launch(cmd.argv, cmd.env, true);
            }
        }
    }
    Timer {
        id: backToIdle
        interval: 2200
        onTriggered: root.phase = "idle"
    }

    Connections {
        target: root.mock ? null : Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (root.pending !== null && !echoResponse) {
                    const p = root.pending;
                    root.pending = null;
                    Greetd.respond(p);
                } else {
                    root.prompt = message.trim().replace(/:$/, "");
                    root.echo = echoResponse;
                    root.phase = "prompt";
                }
            } else if (error) {
                root.error = message;
            } else {
                root.info = message;
            }
        }
        function onAuthFailure(message) {
            root.fail(root.failures >= 2 && message ? message : "Wrong password");
        }
        function onReadyToLaunch() {
            root.launch();
        }
        function onError(error) {
            root.fail(error);
        }
    }

    // ---- mock (test mode / editor) ----
    property int mockStage: 0
    Timer {
        id: mockStep
        interval: 650
        onTriggered: {
            if (root.phase === "busy" && root.prompt !== "") {
                // answered the code: done
                root.prompt = "";
                root.launch();
                return;
            }
            const p = String(root.pending ?? "");
            root.pending = null;
            if (p === "fail" || p === "wrong") {
                root.fail("Wrong password");
            } else if (p === "2fa") {
                root.prompt = "Verification code";
                root.echo = true;
                root.phase = "prompt";
            } else {
                root.launch();
            }
        }
    }

    // the editor's simulation buttons
    function simulate(what) {
        cancel();
        if (what === "fail") {
            fail("Wrong password");
        } else if (what === "prompt") {
            prompt = "Verification code";
            echo = true;
            phase = "prompt";
        } else if (what === "busy") {
            phase = "busy";
            busyDemo.restart();
        } else if (what === "launch") {
            launch();
        } else {
            error = "";
            info = "";
            failures = 0;
            phase = "idle";
        }
    }
    Timer {
        id: busyDemo
        interval: 2500
        onTriggered: if (root.phase === "busy") root.phase = "idle"
    }
}
