pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules.common
import qs.services
import qs.modules.ii.island

// Privacy indicators: mic and camera dots on the pill, and a screen-share activity.
Item {
    id: root

    // Read PipeWire directly: end-4's Privacy service stores link arrays in bool
    // properties, so they read as true even when empty.
    // Mic: an audio source feeding an app's input stream.
    readonly property bool micInUse: Pipewire.linkGroups.values.some(lg => lg.source?.type === PwNodeType.AudioSource && lg.target?.type === PwNodeType.AudioInStream)
    Binding {
        target: IslandState
        property: "micDot"
        value: root.micInUse
    }

    // ---- Camera ----
    // No event exists for V4L2 device use, so poll. fuser exits quietly when nothing holds /dev/video*.
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!camProc.running)
                camProc.running = true;
        }
    }
    Process {
        id: camProc
        command: ["bash", "-c", "fuser /dev/video* 2>/dev/null | grep -q . && echo 1 || echo 0"]
        stdout: StdioCollector {
            id: camCollector
            onStreamFinished: IslandState.camDot = camCollector.text.trim() === "1"
        }
    }

    // ---- Screen sharing ----
    // Screen: a video source (screencast) linked to something.
    readonly property bool sharing: Pipewire.linkGroups.values.some(lg => lg.source?.type === PwNodeType.VideoSource)
    onSharingChanged: {
        if (root.sharing) {
            IslandState.setActivity("screenshare", {
                icon: "screen_share",
                text: Translation.tr("Sharing screen"),
                color: String(Appearance.colors.colError),
                priority: 75
            });
        } else {
            IslandState.clearActivity("screenshare");
        }
    }
}
