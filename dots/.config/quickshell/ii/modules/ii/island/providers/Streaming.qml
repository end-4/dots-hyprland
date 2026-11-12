pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.modules.ii.island

// Moonlight streaming: while a Moonlight window is fullscreen, the pill shows
// elapsed stream time and IslandState.quiet is set (shared rule with GameMode).
// Events drive the check; a 5 s poll runs only while a stream is active.
Item {
    id: root

    property bool streamingNow: false
    property double startedAt: 0 // ms, when the stream was first seen
    property bool pending: false

    function mmss(totalSeconds) {
        const m = Math.floor(totalSeconds / 60);
        const s = totalSeconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function showStreaming() {
        const elapsed = Math.floor((Date.now() - root.startedAt) / 1000);
        IslandState.setActivity("streaming", { icon: "cast", text: Translation.tr("Streaming · %1").arg(root.mmss(elapsed)), priority: 55 });
    }

    function evaluate(output) {
        let live = false;
        try {
            const clients = JSON.parse(output);
            live = clients.some(c => /moonlight/i.test((c.class ?? "") + " " + (c.initialClass ?? "")) && (c.fullscreen ?? 0) > 0);
        } catch (e) {
            live = false;
        }

        if (live && !root.streamingNow)
            root.startedAt = Date.now();
        root.streamingNow = live;

        if (live)
            root.showStreaming();
        else
            IslandState.clearActivity("streaming");
        IslandState.quiet = ("game" in IslandState.activities) || ("streaming" in IslandState.activities);
    }

    function query() {
        if (clientsProc.running) {
            root.pending = true;
            return;
        }
        clientsProc.running = true;
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.evaluate(text)
        }
        onRunningChanged: {
            if (!running && root.pending) {
                root.pending = false;
                clientsProc.running = true;
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindowv2" || event.name === "fullscreen" || event.name === "closewindow")
                root.query();
        }
    }

    // Elapsed time ticks every 2 s while streaming.
    Timer {
        interval: 2000
        running: root.streamingNow
        repeat: true
        onTriggered: root.showStreaming()
    }

    // Catches a stream that ends without a window event we see.
    Timer {
        interval: 5000
        running: root.streamingNow
        repeat: true
        onTriggered: root.query()
    }

    Component.onCompleted: root.query()
}
