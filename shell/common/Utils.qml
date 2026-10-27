pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    function fileName(path) {
        return String(path).slice(String(path).lastIndexOf("/") + 1);
    }

    function stem(path) {
        return fileName(path).replace(/\.[^.]+$/, "");
    }

    function dirName(path) {
        const s = String(path);
        return s.slice(0, Math.max(0, s.lastIndexOf("/")));
    }

    function toUrl(path) {
        if (!path)
            return "";
        path = String(path);
        if (path.startsWith("/"))
            return "file://" + path;
        return path;
    }

    function isVideo(path) {
        return /\.(mp4|webm|mkv|mov|avi|m4v)$/i.test(String(path));
    }
    function isGif(path) {
        return /\.gif$/i.test(String(path));
    }
    function isImage(path) {
        return /\.(png|jpe?g|webp|bmp|svg|avif|jxl)$/i.test(String(path));
    }
    // "image" | "gif" | "video" | "" for a media file
    function mediaKind(path) {
        return isVideo(path) ? "video" : isGif(path) ? "gif" : isImage(path) ? "image" : "";
    }

    function greeting() {
        const h = new Date().getHours();
        if (h < 5)
            return "Still up";
        if (h < 12)
            return "Good morning";
        if (h < 17)
            return "Good afternoon";
        if (h < 22)
            return "Good evening";
        return "Good night";
    }

    function capitalize(s) {
        s = String(s ?? "");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function initials(name) {
        const parts = String(name ?? "").trim().split(/\s+/).filter(p => p.length > 0);
        if (parts.length === 0)
            return "?";
        return (parts[0][0] + (parts.length > 1 ? parts[parts.length - 1][0] : "")).toUpperCase();
    }

    // JSON-safe deep copy and merge (themes are plain JSON objects)
    function clone(o) {
        return JSON.parse(JSON.stringify(o ?? {}));
    }
    function merge(base, over) {
        const out = clone(base);
        for (const k in (over ?? {})) {
            const v = over[k];
            if (v && typeof v === "object" && !Array.isArray(v) && out[k] && typeof out[k] === "object" && !Array.isArray(out[k]))
                out[k] = merge(out[k], v);
            else
                out[k] = clone(v);
        }
        return out;
    }
    function getPath(o, path) {
        let cur = o;
        for (const k of String(path).split(".")) {
            if (cur === null || cur === undefined)
                return undefined;
            cur = cur[k];
        }
        return cur;
    }
    function withPath(o, path, value) {
        const out = clone(o);
        const keys = String(path).split(".");
        let cur = out;
        for (let i = 0; i < keys.length - 1; i++) {
            if (typeof cur[keys[i]] !== "object" || cur[keys[i]] === null)
                cur[keys[i]] = {};
            cur = cur[keys[i]];
        }
        cur[keys[keys.length - 1]] = value;
        return out;
    }

    function slug(s) {
        return String(s ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "theme";
    }

    // Split a desktop-entry Exec line into argv: honours "quotes" and \escapes,
    // drops field codes (%f, %U, …) and turns %% into %.
    function splitExec(line) {
        const out = [];
        let cur = "";
        let quoted = false;
        let has = false;
        const s = String(line ?? "");
        for (let i = 0; i < s.length; i++) {
            const c = s[i];
            if (c === "\\" && i + 1 < s.length) {
                cur += s[++i];
                has = true;
            } else if (c === "\"") {
                quoted = !quoted;
                has = true;
            } else if (!quoted && (c === " " || c === "\t")) {
                if (has)
                    out.push(cur);
                cur = "";
                has = false;
            } else {
                cur += c;
                has = true;
            }
        }
        if (has)
            out.push(cur);
        return out.map(a => a.replace(/%%/g, "\u0000")).filter(a => !/^%[a-zA-Z]$/.test(a)).map(a => a.replace(/%[a-zA-Z]/g, "").replace(/\u0000/g, "%"));
    }

    // run a shell snippet detached; extra args become $1, $2, ...
    function sh(script, ...args) {
        Quickshell.execDetached(["sh", "-c", script, "plm"].concat(args.map(a => String(a))));
    }
}
