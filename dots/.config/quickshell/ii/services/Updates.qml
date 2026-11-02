pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Actualizaciones pendientes (repos + AUR). Una vez activado sigue corriendo en segundo plano:
// consulta la red cada 30 min y cachea el resultado en ~/.cache/ii-dash/updates.json.
Singleton {
    id: root

    property bool active: false
    property bool ok: true
    property bool busy: false
    property string error: ""
    property string detail: ""
    readonly property string errorText: error === "no_checkupdates"
        ? Translation.tr("checkupdates is not installed (sudo pacman -S pacman-contrib)")
        : error === "query_failed"
            ? Translation.tr("Could not query the repositories") + (detail ? ": " + detail : "") : error
    property var repo: []             // [{n, old, new, reboot}]
    property var aur: []
    property real ts: 0               // ultima comprobacion (epoch s)
    property real lastUpgrade: 0      // ultima actualizacion completa (epoch s)
    property real now: 0
    property string helper: ""
    property var updateCmd: []

    readonly property int count: repo.length + aur.length
    readonly property bool needsReboot: repo.some(p => p.reboot)

    // Texto relativo ("5 min ago"); lee `now` para que los bindings se refresquen cada minuto.
    function ago(t) {
        if (!t) return Translation.tr("never");
        const s = Math.max(0, now - t);
        if (s < 60) return Translation.tr("just now");
        if (s < 3600) return Translation.tr("%1 min ago").arg(Math.round(s / 60));
        if (s < 86400) return Translation.tr("%1 h ago").arg(Math.floor(s / 3600));
        return Translation.tr("%1 d ago").arg(Math.floor(s / 86400));
    }

    function refresh() {
        if (proc.running) proc.write("refresh\n");
    }

    function handle(line) {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }
        ok = d.ok; error = d.err; detail = d.detail || ""; busy = d.busy;
        repo = d.repo; aur = d.aur;
        ts = d.ts; lastUpgrade = d.lastUpgrade;
        helper = d.helper; updateCmd = d.updateCmd;
        now = Date.now() / 1000;
    }

    Process {
        id: proc
        running: root.active
        command: ["python3", Quickshell.shellPath("scripts/dash/dashupdates.py")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
