import QtQuick
import QtMultimedia
import Quickshell
import qs.common

// One picture: a still image, an animated GIF, or a looping live video
// (Qt Multimedia, hardware-decoded where the driver allows, never with sound).
// Videos show `poster` until their first frame arrives.
Item {
    id: root

    // image | gif | video
    property string kind: "image"
    property string source: ""
    property string poster: ""
    // crop | fit | stretch
    property string fill: "crop"
    property real speed: 1
    property bool loop: true
    property bool playing: true

    property bool gotFrame: false
    property bool failed: false
    readonly property bool ready: failed || (kind === "video" ? (gotFrame || posterImg.status === Image.Ready || posterImg.status === Image.Error && poster === "") : kind === "gif" ? gif.status === AnimatedImage.Ready || gif.status === AnimatedImage.Error : img.status === Image.Ready || img.status === Image.Error)

    readonly property int imageFill: fill === "fit" ? Image.PreserveAspectFit : fill === "stretch" ? Image.Stretch : Image.PreserveAspectCrop

    onSourceChanged: {
        gotFrame = false;
        failed = false;
    }

    Image {
        id: img
        anchors.fill: parent
        visible: root.kind === "image"
        source: root.kind === "image" ? root.source : ""
        fillMode: root.imageFill
        sourceSize.width: 2560
        asynchronous: true
        smooth: true
        mipmap: true
        cache: false
    }

    AnimatedImage {
        id: gif
        anchors.fill: parent
        visible: root.kind === "gif"
        source: root.kind === "gif" ? root.source : ""
        fillMode: root.imageFill
        playing: root.playing
        speed: root.speed
        cache: false
        smooth: true
    }

    // ---- live video ----
    Image {
        id: posterImg
        anchors.fill: parent
        visible: root.kind === "video" && !root.gotFrame
        source: root.kind === "video" ? root.poster : ""
        fillMode: root.imageFill
        sourceSize.width: 2560
        asynchronous: true
        cache: false
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        visible: root.kind === "video" && root.gotFrame
        fillMode: root.fill === "fit" ? VideoOutput.PreserveAspectFit : root.fill === "stretch" ? VideoOutput.Stretch : VideoOutput.PreserveAspectCrop
    }

    Connections {
        target: root.kind === "video" && !root.gotFrame ? vo.videoSink : null
        function onVideoFrameChanged() {
            root.gotFrame = true;
        }
    }

    MediaPlayer {
        id: player
        source: root.kind === "video" ? root.source : ""
        videoOutput: vo
        loops: root.loop ? MediaPlayer.Infinite : 1
        playbackRate: root.speed
        onSourceChanged: if (source.toString() !== "" && root.playing) play()
        onErrorOccurred: (error, errorString) => {
            console.warn("PLM: video:", errorString);
            root.failed = true;
        }
    }
    onPlayingChanged: {
        if (kind !== "video")
            return;
        if (playing)
            player.play();
        else
            player.pause();
    }

    // colours for a video without a poster: sample a frame of the video itself
    property bool reportFrame: false
    Timer {
        running: root.reportFrame && root.kind === "video" && root.gotFrame && root.poster === ""
        interval: 900
        onTriggered: vo.grabToImage(r => {
            const dir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
            const path = dir + "/plm-frame-" + Date.now() + ".png";
            if (!r.saveToFile(path))
                return;
            // keep only the newest frame
            if (Theme.liveFrame !== "")
                Quickshell.execDetached(["rm", "-f", Theme.liveFrame.replace(/^file:\/\//, "")]);
            Theme.liveFrame = "file://" + path;
        }, Qt.size(480, 270))
    }

    // a video that never shows a frame (no codec, no GPU decode): don't hold the fade forever
    Timer {
        running: root.kind === "video" && !root.ready
        interval: 4000
        onTriggered: root.failed = true
    }
}
