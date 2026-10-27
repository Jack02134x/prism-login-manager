import QtQuick
import QtQuick.Particles
import qs.common

// Ambient particles over the background: snow | fireflies | stars | embers | rain.
Item {
    id: root

    property string kind: Theme.fx.particles
    property int count: Theme.fx.particleCount
    readonly property bool on: kind !== "none" && kind !== ""

    readonly property var spec: ({
        snow: { img: "glowdot", life: 9000, size: 10, sizeVar: 8, alpha: 0.55, angle: 90, angleVar: 18, speed: 70, speedVar: 40, from: "top", tint: 0.15 },
        fireflies: { img: "glowdot", life: 7000, size: 14, sizeVar: 10, alpha: 0.7, angle: 270, angleVar: 180, speed: 14, speedVar: 12, from: "all", tint: 1 },
        stars: { img: "star", life: 4500, size: 9, sizeVar: 7, alpha: 0.85, angle: 0, angleVar: 180, speed: 1, speedVar: 1, from: "all", tint: 0.35 },
        embers: { img: "glowdot", life: 8000, size: 9, sizeVar: 7, alpha: 0.75, angle: 270, angleVar: 14, speed: 90, speedVar: 50, from: "bottom", tint: 1 },
        rain: { img: "fuzzydot", life: 1600, size: 4, sizeVar: 2, alpha: 0.45, angle: 100, angleVar: 3, speed: 900, speedVar: 200, from: "top", tint: 0.2 }
    })
    readonly property var s: spec[kind] ?? spec.snow

    ParticleSystem {
        id: sys
        running: root.on && root.visible
    }

    ImageParticle {
        system: sys
        visible: root.on
        source: "qrc:///particleresources/" + root.s.img + ".png"
        color: Theme.mix(Qt.color("white"), Theme.accent1, root.s.tint)
        colorVariation: root.kind === "fireflies" || root.kind === "embers" ? 0.25 : 0.05
        alpha: root.s.alpha
        alphaVariation: 0.4
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        system: sys
        enabled: root.on
        x: 0
        y: root.s.from === "top" ? -20 : root.s.from === "bottom" ? root.height + 10 : 0
        width: root.width
        height: root.s.from === "all" ? root.height : 10
        emitRate: Math.max(1, root.count / (root.s.life / 1000))
        lifeSpan: root.s.life
        lifeSpanVariation: root.s.life * 0.3
        size: root.s.size
        sizeVariation: root.s.sizeVar
        endSize: root.kind === "embers" ? 2 : -1
        velocity: AngleDirection {
            angle: root.s.angle
            angleVariation: root.s.angleVar
            magnitude: root.s.speed
            magnitudeVariation: root.s.speedVar
        }
    }

    // snow and embers drift sideways, fireflies wander
    Wander {
        system: sys
        enabled: root.kind === "snow" || root.kind === "fireflies" || root.kind === "embers"
        xVariance: root.kind === "fireflies" ? 60 : 30
        yVariance: root.kind === "fireflies" ? 60 : 0
        pace: root.kind === "fireflies" ? 40 : 20
    }
}
