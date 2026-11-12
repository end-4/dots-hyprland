import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// One-shot particle burst: paper confetti (Claude finished) or "?" marks (needs permission).
// Particles follow closed-form physics from a single frame counter, so only one
// property changes per frame, and the timer runs only during a burst (~1.5 s).
Item {
    id: root
    property var particles: []
    property int frame: 0
    readonly property bool active: particles.length > 0
    readonly property var colors: ["#d97757", "#e8a07f", "#c15f3c", "#f4efe9", Appearance.colors.colPrimary, Appearance.colors.colTertiary]

    function burst(x: real, y: real, kind: string): void {
        const q = kind === "question";
        const n = q ? 20 : 46;
        const out = [];
        for (let i = 0; i < n; i++) {
            const a = Math.PI * (0.12 + 0.76 * Math.random());
            const sp = (q ? 3.0 : 4.2) + Math.random() * 3.2;
            out.push({
                x0: x, y0: y,
                vx: Math.cos(a) * sp * (Math.random() < 0.5 ? -1 : 1),
                vy: Math.sin(a) * sp * 0.5 + 0.6,
                g: q ? 0.07 : 0.11,
                r0: Math.random() * 360, vr: (Math.random() - 0.5) * 20,
                w: 5 + Math.random() * 4, h: 3 + Math.random() * 3,
                size: 18 + Math.random() * 12,
                color: root.colors[i % root.colors.length],
                life: q ? 95 : 85,
                q: q
            });
        }
        root.frame = 0;
        root.particles = out;
    }

    Timer {
        interval: 16
        repeat: true
        running: root.active
        onTriggered: {
            root.frame++;
            if (root.frame > 100)
                root.particles = [];
        }
    }

    Repeater {
        model: root.particles
        Item {
            required property var modelData
            readonly property real t: root.frame
            // x drifts with drag (~0.985/frame), y falls under gravity.
            readonly property real drag: (1 - Math.pow(0.985, t)) / 0.015
            x: modelData.x0 + modelData.vx * drag
            y: modelData.y0 + modelData.vy * t + 0.5 * modelData.g * t * t
            rotation: modelData.r0 + modelData.vr * t * (modelData.q ? 0.3 : 1)
            opacity: Math.max(0, 1 - t / modelData.life)

            Rectangle {
                visible: !modelData.q
                width: modelData.w
                height: modelData.h
                x: -width / 2
                y: -height / 2
                radius: 1
                color: modelData.color
            }
            StyledText {
                visible: modelData.q
                anchors.centerIn: parent
                text: "?"
                font.pixelSize: modelData.size
                font.weight: Font.DemiBold
                color: modelData.color
            }
        }
    }
}
