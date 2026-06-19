import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root
    name: Translation.tr("Screen recorder")
    hasStatusText: false
    toggled: recordingProc.running
    icon: "screen_record"

    property bool recording: false

    Process {
        id: recordingProc
        running: false
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.recording = (exitCode === 0);
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: recordingProc.running = true
    }

    mainAction: () => {
        if (root.recording) {
            Quickshell.execDetached(["bash", "-c", "kill -INT $(pidof wf-recorder)"]);
        } else {
            GlobalStates.sidebarRightOpen = false;
            delayedActionTimer.start();
        }
    }

    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
        }
    }

    tooltipText: Translation.tr("Screen recorder")
}
