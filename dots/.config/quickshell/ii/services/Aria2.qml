pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Cliente de aria2 (JSON-RPC). Corre solo mientras `active` sea true.
Singleton {
    id: root

    property bool active: false
    property bool ok: false
    property string error: ""
    property int port: 0
    readonly property string errorText: error === "unreachable"
        ? Translation.tr("aria2 is not responding on port %1").arg(port) : error

    property real dlSpeed: 0          // B/s
    property real ulSpeed: 0
    property int nActive: 0
    property int nWaiting: 0
    property int nStopped: 0
    property var activeList: []       // [{gid, name, status, total, done, speed, up, conns, err}]
    property var waitingList: []      // incluye las pausadas (status "paused")
    property var stoppedList: []

    readonly property int histLen: 60
    property var speedHist: []
    readonly property real speedPeak: Math.max(102400, ...speedHist)

    function cmd(c) {
        if (proc.running) proc.write(c + "\n");
    }

    function handle(line) {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }
        ok = d.ok === true;
        if (!ok) {
            error = d.err || "unreachable";
            port = d.port || 0;
            return;
        }
        error = "";
        dlSpeed = d.stat.dl; ulSpeed = d.stat.ul;
        nActive = d.stat.active; nWaiting = d.stat.waiting; nStopped = d.stat.stopped;
        activeList = d.active; waitingList = d.waiting; stoppedList = d.stopped;
        const h = speedHist.slice(-(histLen - 1));
        h.push(d.stat.dl);
        speedHist = h;
    }

    Process {
        id: proc
        running: root.active
        command: ["python3", Quickshell.shellPath("scripts/dash/dasharia.py")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
