pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

// The active theme: theme.json merged over `defaults`, plus the colours,
// fonts and background it resolves to. The editor changes it live with set().
//
// Colours come from (colors.source):
//   auto       the user's Prism desktop when synced, else the wallpaper, else custom
//   prism      the synced Prism palette (plm sync)
//   wallpaper  the background image's own dominant colours
//   custom     colors.accent / accent2 / accent3
Singleton {
    id: root

    // folder of the loaded theme (relative asset paths resolve against it)
    property string dir: ""
    property string id: ""
    property bool ready: false
    property var data: defaults
    property bool dirty: false
    property var history: []
    property var future: []

    readonly property var defaults: ({
        name: "Untitled",
        author: "",
        description: "",
        version: 1,
        // prism | glass | minimal | coverflow | custom (custom loads `main` from the theme folder)
        layout: "prism",
        main: "Main.qml",
        background: {
            // media (image, gif or video) | prism | shader | gradient | color
            type: "shader",
            source: "",
            // shown while a video starts, and used for colours when the source is a video
            fallback: "",
            shader: "aurora",
            fill: "crop",
            speed: 1,
            loop: true,
            blur: 0,
            dim: 0.2,
            saturation: 0,
            zoom: 1.0,
            // how far the picture follows the mouse (0 = still)
            parallax: 0.0,
            // extra blur while typing, and when idle (ambient)
            focusBlur: 0.5,
            colors: ["#10131c", "#24163a", "#0b2730"],
            angle: 135
        },
        colors: {
            source: "auto",
            accent: "#82d5ca",
            accent2: "#aecae6",
            accent3: "#cbb7ff",
            text: "#ffffff",
            textDim: "#ccd0da",
            surface: "#000000",
            surfaceAlpha: 0.36,
            border: 0.16,
            error: "#ff8a80"
        },
        fonts: {
            ui: "Adwaita Sans",
            display: "Roboto",
            mono: "Adwaita Mono"
        },
        clock: {
            show: true,
            format: "HH:mm",
            dateFormat: "dddd, d MMMM",
            size: 200,
            weight: 900,
            gradient: true,
            uppercaseDate: true,
            dateSpacing: 6,
            greeting: false
        },
        panel: {
            side: "left",
            width: 440,
            radius: 28,
            blur: 0.9,
            opacity: 0.42,
            border: true
        },
        avatar: {
            show: true,
            size: 112,
            // circle | squircle | square
            shape: "circle",
            // gradient | accent | none
            ring: "gradient",
            ringWidth: 4,
            spin: true
        },
        input: {
            width: 360,
            height: 52,
            radius: 26,
            // glass | solid | underline
            style: "glass",
            placeholder: "Password",
            mask: "●"
        },
        effects: {
            aurora: 0,
            // none | snow | fireflies | stars | embers | rain
            particles: "none",
            particleCount: 80,
            vignette: 0.45,
            grain: 0,
            // rise | zoom | fade | blur | none
            intro: "rise",
            introMs: 1100,
            // zoom | fade | blur | none
            outro: "zoom",
            // seconds idle before only the clock stays (-1 = use plm.json)
            ambientAfter: -1,
            glow: true
        },
        show: {
            users: true,
            sessions: true,
            power: true,
            battery: true,
            capsLock: true,
            hostname: true,
            hints: true
        }
    })

    // ---- loading & editing ---------------------------------------------------
    function load(json, folder, themeId) {
        dir = folder;
        id = themeId ?? Utils.fileName(folder);
        data = Utils.merge(defaults, normalise(json));
        dirty = false;
        history = [];
        future = [];
        ready = true;
    }
    // older / shorthand spellings
    function normalise(json) {
        const j = Utils.clone(json);
        const t = j.background?.type;
        if (t === "image" || t === "video" || t === "gif" || t === "live")
            j.background.type = "media";
        return j;
    }

    function get(path) {
        return Utils.getPath(data, path);
    }
    function set(path, value) {
        if (JSON.stringify(get(path)) === JSON.stringify(value))
            return;
        history = history.concat([data]).slice(-120);
        future = [];
        data = Utils.withPath(data, path, value);
        dirty = true;
    }
    function replace(obj) {
        history = history.concat([data]).slice(-120);
        future = [];
        data = Utils.merge(defaults, normalise(obj));
        dirty = true;
    }
    function undo() {
        if (history.length === 0)
            return;
        future = [data].concat(future);
        data = history[history.length - 1];
        history = history.slice(0, -1);
        dirty = true;
    }
    function redo() {
        if (future.length === 0)
            return;
        history = history.concat([data]);
        data = future[0];
        future = future.slice(1);
        dirty = true;
    }

    // a theme path as a URL: absolute, ~/…, or relative to the theme folder
    function resolve(p) {
        p = String(p ?? "");
        if (p === "")
            return "";
        if (/^(file|qrc|https?):/.test(p))
            return p;
        if (p.startsWith("~/"))
            return "file://" + Config.home + p.slice(1);
        if (p.startsWith("/"))
            return "file://" + p;
        return "file://" + dir + "/" + p;
    }

    // ---- sections ------------------------------------------------------------
    readonly property var bg: data.background
    readonly property var col: data.colors
    readonly property var clock: data.clock
    readonly property var panel: data.panel
    readonly property var avatar: data.avatar
    readonly property var input: data.input
    readonly property var fx: data.effects
    readonly property var show: data.show
    readonly property string layout: data.layout

    // ---- background ----------------------------------------------------------
    // "prism" follows the selected user's synced desktop; without a sync it uses
    // the theme's own source, or the shader.
    readonly property bool usePrism: bg.type === "prism" && Config.prismSync && Sync.available
    readonly property string bgType: {
        if (usePrism)
            return "media";
        if (bg.type === "prism")
            return bg.source !== "" ? "media" : "shader";
        return bg.type;
    }
    readonly property string bgSource: usePrism ? Sync.wallpaper : resolve(bg.source)
    readonly property string bgKind: bgType === "media" ? (Utils.mediaKind(bgSource) || "image") : ""
    readonly property string bgPoster: usePrism ? Sync.poster : resolve(bg.fallback)
    // blurring a procedural shader only turns it to fog: blur applies to pictures
    readonly property real bgBlur: bgType === "shader" ? 0 : bg.blur
    readonly property real bgFocusBlur: bgType === "shader" ? bg.focusBlur * 0.25 : bg.focusBlur
    readonly property real ambientAfter: fx.ambientAfter >= 0 ? fx.ambientAfter : Config.ambientAfter

    // ---- colours -------------------------------------------------------------
    // a frame of the playing video, for colours when it has no poster (see MediaLayer)
    property string liveFrame: ""
    onBgSourceChanged: liveFrame = ""

    ColorQuantizer {
        id: quant
        source: root.bgType !== "media" ? "" : Utils.isVideo(root.bgSource) ? (root.bgPoster || root.liveFrame) : root.bgSource
        depth: 3
        rescaleSize: 96
    }

    function vivid(c) {
        const h = c.hslHue < 0 ? 0.5 : c.hslHue;
        const sat = Math.min(1, Math.max(c.hslSaturation * 1.35, 0.5));
        return Qt.hsla(h, sat, 0.7, 1);
    }
    // quantized colours, most colourful first (greys dropped when possible)
    readonly property var wallColors: {
        const cs = Array.from(quant.colors ?? []);
        const scored = cs.map(c => ({ c, s: c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.4) }));
        const colourful = scored.filter(x => x.c.hslSaturation > 0.18);
        return (colourful.length >= 2 ? colourful : scored).sort((a, b) => b.s - a.s).map(x => vivid(x.c));
    }

    readonly property string paletteSource: {
        const s = col.source;
        if (s === "prism" || (s === "auto" && Sync.available && Config.prismSync))
            return Sync.available ? "prism" : "custom";
        if (s === "wallpaper" || s === "auto")
            return wallColors.length >= 1 ? "wallpaper" : "custom";
        return "custom";
    }
    readonly property var targetAccents: {
        // the same three accents Prism's lock-screen clock uses (always told apart)
        const acc = Sync.palette?.accents ?? [];
        if (paletteSource === "prism" && acc.length >= 8)
            return [Qt.color(acc[0]), Qt.color(acc[4]), Qt.color(acc[7])];
        if (paletteSource === "prism" && Sync.gradient.length >= 3)
            return Sync.gradient.slice(0, 3).map(h => Qt.color(h));
        if (paletteSource === "wallpaper")
            return [wallColors[0], wallColors[1] ?? wallColors[0], wallColors[2] ?? wallColors[1] ?? wallColors[0]];
        return [Qt.color(col.accent), Qt.color(col.accent2), Qt.color(col.accent3)];
    }

    property color accent1: targetAccents[0]
    property color accent2: targetAccents[1]
    property color accent3: targetAccents[2]
    Behavior on accent1 { ColorAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    Behavior on accent2 { ColorAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    Behavior on accent3 { ColorAnimation { duration: 1200; easing.type: Easing.InOutCubic } }

    readonly property color text: col.text
    readonly property color textDim: col.textDim
    readonly property color surface: alpha(Qt.color(col.surface), col.surfaceAlpha)
    readonly property color stroke: alpha(text, col.border)
    readonly property color error: col.error

    function accent(i) {
        const a = [accent1, accent2, accent3];
        return a[((i % 3) + 3) % 3];
    }
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    // readable text colour for a background
    function on(c) {
        const l = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return l > 0.55 ? "#101418" : "#f4f7f6";
    }
    function hex(c) {
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    // ---- type & shape --------------------------------------------------------
    readonly property string font: data.fonts.ui
    readonly property string display: data.fonts.display
    readonly property string mono: data.fonts.mono
    readonly property string iconFont: "Symbols Nerd Font"

    readonly property QtObject r: QtObject {
        readonly property int xs: 6
        readonly property int sm: 10
        readonly property int md: 14
        readonly property int lg: 20
        readonly property int xl: 28
    }
}
