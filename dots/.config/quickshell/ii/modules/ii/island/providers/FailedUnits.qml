pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.ii.island

// Failed systemd units (system and user) as a red idle glance item. Clicking it opens
// a terminal with the full lists. Counted every 2 min; the first count runs right at load.
Item {
    id: root

    readonly property string glanceId: "failed"

    // Output is "<system count> <user count>". A bad output keeps the last state.
    function onCounts(output) {
        const parts = output.trim().split(/\s+/).map(s => parseInt(s));
        if (parts.length < 2 || isNaN(parts[0]) || isNaN(parts[1]))
            return;
        const total = parts[0] + parts[1];
        if (total > 0) {
            IslandState.setGlance(root.glanceId, {
                icon: "warning",
                text: (total > 1 ? Translation.tr("%1 failed units") : Translation.tr("%1 failed unit")).arg(total),
                color: String(Appearance.colors.colError),
                priority: 90,
                // The user's terminal from Config.options.apps.terminal (end-4: "only for shell actions").
                command: ["bash", "-c", Config.options.apps.terminal + " bash -c 'systemctl --failed; systemctl --user --failed; read -rp \"Press Enter to close\"'"]
            });
        } else {
            IslandState.clearGlance(root.glanceId);
        }
    }

    // Never overlaps: a request while a run is in progress is dropped.
    function check() {
        if (!count.running)
            count.running = true;
    }

    Process {
        id: count
        // grep -c . prints 0 when there are no failed units, so the output is always two numbers.
        command: ["bash", "-c", "n1=$(systemctl --failed --no-legend --plain 2>/dev/null | grep -c .); n2=$(systemctl --user --failed --no-legend --plain 2>/dev/null | grep -c .); echo $n1 $n2"]
        stdout: StdioCollector {
            onStreamFinished: root.onCounts(text)
        }
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}
