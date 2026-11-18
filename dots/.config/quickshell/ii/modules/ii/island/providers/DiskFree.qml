pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.services
import qs.modules.ii.island

// Free space on / and /home as idle glance items. Both are usually one filesystem, so
// entries with the same size and free bytes are listed once, under the first mount (/).
// Low free space raises the priority; very low also turns the item red.
Item {
    id: root

    readonly property real lowPct: 0.15
    readonly property real criticalPct: 0.10

    // Binary units: GB with no decimals from 10 GB up, one decimal below; TB from 1 TB.
    function formatBytes(b) {
        const GB = 1073741824;
        const TB = GB * 1024;
        if (b >= TB)
            return (b / TB).toFixed(1) + " TB";
        if (b >= 10 * GB)
            return Math.round(b / GB) + " GB";
        return (b / GB).toFixed(1) + " GB";
    }

    // Lines are "avail size mount" (df header already dropped by the shell pipeline).
    function onDf(output) {
        const seen = {};
        for (const line of output.split("\n")) {
            const m = line.match(/^\s*(\d+)\s+(\d+)\s+(\S.*?)\s*$/);
            if (!m)
                continue;
            const avail = parseInt(m[1]);
            const size = parseInt(m[2]);
            const mount = m[3];

            const fsKey = size + ":" + avail;
            if (seen[fsKey])
                continue;
            seen[fsKey] = true;

            const pctFree = size > 0 ? avail / size : 1;
            IslandState.setGlance("disk-" + mount, {
                icon: "hard_drive",
                text: mount !== "/" ? Translation.tr("%1 free %2").arg(formatBytes(avail)).arg(mount) : Translation.tr("%1 free").arg(formatBytes(avail)),
                priority: pctFree < root.lowPct ? 80 : 30,
                color: pctFree < root.criticalPct ? String(Appearance.colors.colError) : pctFree < root.lowPct ? "#f0883e" : ""
            });
        }
    }

    // Never overlaps: a request while a run is in progress is dropped.
    function check() {
        if (!df.running)
            df.running = true;
    }

    Process {
        id: df
        command: ["bash", "-c", "df -B1 --output=avail,size,target / /home 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: root.onDf(text)
        }
    }

    // First check 20 s after load, then every 5 min.
    Timer {
        interval: 20000
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: root.check()
    }
}
