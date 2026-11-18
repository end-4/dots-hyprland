pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "monitorParse.js" as MP

/**
 * Extra system stats for the monitor sidebar (GPU, temps, frequency, top processes).
 * Polls only while the panel is open. CPU/RAM come from ResourceUsage.
 */
Singleton {
    id: root

    property bool open: false
    readonly property bool active: open

    property var gpu: null
    property bool gpuAvailable: false
    property bool gpuProbeFailed: false // stop calling nvidia-smi once it fails, until the panel reopens
    property list<real> gpuHistory: []
    property var procs: []
    property real cpuFreq: 0
    property real cpuTemp: -1

    onOpenChanged: {
        if (open) {
            root.gpuProbeFailed = false;
            pollProc.running = true;
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        onTriggered: if (!pollProc.running) pollProc.running = true
    }

    Process {
        id: pollProc
        command: ["bash", "-c", (root.gpuProbeFailed ? "" : "timeout 2 nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>&1; ")
            + "echo '@@'; top -b -n 2 -d 0.5 -w 512 | awk '/^top -/{f++} f==2 && $1 ~ /^[0-9]+$/ {print $12, $9}' | sort -k2 -nr | head -8; echo '@@'; grep 'cpu MHz' /proc/cpuinfo; echo '@@'; sensors -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@\n");
                if (parts.length < 4)
                    return;
                const g = root.gpuProbeFailed ? null : MP.parseNvidiaSmi(parts[0]);
                if (g) {
                    root.gpu = g;
                    root.gpuAvailable = true;
                    const h = root.gpuHistory.slice(-(ResourceUsage.historyLength - 1));
                    h.push(g.util / 100);
                    root.gpuHistory = h;
                } else if (!root.gpuProbeFailed) {
                    root.gpuAvailable = false;
                    root.gpuProbeFailed = true;
                }
                const skip = ["top", "bash", "awk", "sort", "head", "grep", "sensors"];
                root.procs = MP.parsePs(parts[1], 8).filter(p => skip.indexOf(p.name) < 0).slice(0, 5);
                root.cpuFreq = MP.parseCpuFreqMHz(parts[2]) ?? 0;
                root.cpuTemp = MP.pickCpuTemp(parts[3]) ?? -1;
            }
        }
    }
}
