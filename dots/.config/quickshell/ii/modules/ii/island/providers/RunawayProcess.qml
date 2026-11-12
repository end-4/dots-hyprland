pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.services
import qs.modules.ii.island
import "cpuPressure.js" as Pressure

// Warns when the whole machine is nearly out of CPU: overall usage near 90% on 3 polls in a row
// (about 30 s). The card names the busiest program and offers Kill. One program using 100%+ of a
// core is normal and says nothing about the machine, so it never warns by itself.
Item {
    id: root

    readonly property int pollMs: 10000
    // hot: overall % that counts as "near 90". cool: must drop below this before it can warn again.
    readonly property var limits: ({ hot: 88, cool: 75, polls: 3 })
    // Compositor, shell, and the sampler itself: never named as the culprit.
    readonly property var ignored: ["top", "kwin", "Hyprland", "qs", "quickshell"]

    property var pressure: ({ count: 0, warned: false })
    property int overallPercent: 0

    function onSample(text) {
        const sample = Pressure.parseSample(text, root.ignored);
        if (sample.top === null)
            return;
        const name = sample.top.name;
        IslandState.pushCard("cpu-" + sample.top.pid, {
            icon: "local_fire_department",
            title: Translation.tr("%1 is using the most CPU").arg(name),
            body: Translation.tr("CPU at %1% · this program: %2%").arg(root.overallPercent).arg(Pressure.machineShare(sample.top.cpu, sample.cores)),
            accent: String(Appearance.colors.colError),
            ttl: 12000,
            actions: [
                { text: Translation.tr("Kill"), command: ["kill", sample.top.pid] },
                { text: Translation.tr("Ignore"), command: ["true"] }
            ]
        });
    }

    // top runs twice so the figures are a real sample, not the average since boot.
    // Only started when a warning is due; a normal poll just reads ResourceUsage.
    Process {
        id: sampler
        command: ["sh", "-c", "nproc; LC_ALL=C top -b -n 2 -d 0.5 -w 512 | awk '/^top -/{f++} f==2 && $1 ~ /^[0-9]+$/ {print $1, $9, $12}' | sort -k2 -nr | head -6"]
        stdout: StdioCollector {
            onStreamFinished: root.onSample(text)
        }
    }

    Timer {
        interval: root.pollMs
        running: true
        repeat: true
        onTriggered: {
            root.overallPercent = Math.round(ResourceUsage.cpuUsage * 100);
            root.pressure = Pressure.step(root.pressure, root.overallPercent, root.limits);
            if (root.pressure.warn)
                sampler.running = true;
        }
    }
}
