pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Estadisticas del sistema para el dashboard del sidebar izquierdo.
// El proceso solo corre mientras `active` sea true (sidebar visible).
Singleton {
    id: root

    property bool active: false
    property string mode: "summary"   // summary | cpu | mem | net | gpu

    property real cpuPct: 0
    property real cpuTemp: 0
    property real memUsed: 0          // kB
    property real memTotal: 1         // kB
    property real swapUsed: 0
    property real swapTotal: 0
    property real netRx: 0            // B/s
    property real netTx: 0
    property real gpuUtil: 0
    property real gpuFreq: 0          // MHz
    property real gpuMax: 0
    property var rows: []
    property string error: ""
    readonly property string errorText: error === "no_nethogs"
        ? Translation.tr("nethogs is not installed (sudo pacman -S nethogs)")
        : error === "nethogs_exited" ? Translation.tr("nethogs exited (missing capabilities?)") : error

    readonly property int histLen: 60
    property var cpuHist: []
    property var memHist: []
    property var rxHist: []
    property var txHist: []
    property var gpuHist: []
    readonly property real memPct: memTotal > 0 ? 100 * memUsed / memTotal : 0
    readonly property real netPeak: Math.max(10240, ...rxHist, ...txHist)

    function push(arr, v) {
        const a = arr.slice(-(histLen - 1));
        a.push(v);
        return a;
    }

    function setMode(m) {
        mode = m;
        rows = [];
        error = "";
        if (proc.running) proc.write(m + "\n");
    }

    function handle(line) {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }
        cpuPct = d.cpu; cpuTemp = d.temp;
        memUsed = d.mem_used; memTotal = d.mem_total;
        swapUsed = d.swap_used; swapTotal = d.swap_total;
        netRx = d.rx; netTx = d.tx;
        gpuUtil = d.gpu; gpuFreq = d.gpu_freq; gpuMax = d.gpu_max;
        cpuHist = push(cpuHist, d.cpu);
        memHist = push(memHist, memPct);
        rxHist = push(rxHist, d.rx);
        txHist = push(txHist, d.tx);
        gpuHist = push(gpuHist, d.gpu);
        if (d.mode === mode) {   // descarta filas de un modo anterior
            rows = d.rows;
            error = d.err;
        }
    }

    Process {
        id: proc
        running: root.active
        command: ["python3", Quickshell.shellPath("scripts/dash/dashstats.py"), root.mode]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
