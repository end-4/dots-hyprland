pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: true
    property bool daemonEnabled: true
    property string statePath: Directories.orbitbarStatePath
    property string socketPath: Directories.orbitbarSocketPath
    property string bridgeScriptPath: `${Directories.scriptPath}/orbitbar/orbitbar_bridge.py`
    property var state: ({ "updated_at": "", "session_count": 0, "sessions": [] })
    property var sessions: []
    property int sessionCount: 0
    property string lastUpdatedAt: ""
    property bool daemonRunning: bridgeProcess.running

    function load() {
        if (daemonEnabled && !bridgeProcess.running)
            bridgeProcess.running = true;
        stateFile.reload();
    }

    function resetState() {
        root.state = { "updated_at": "", "session_count": 0, "sessions": [] };
        root.sessions = [];
        root.sessionCount = 0;
        root.lastUpdatedAt = "";
    }

    function parseState(raw) {
        if (!raw || raw.trim().length === 0) {
            resetState();
            return;
        }

        try {
            const parsed = JSON.parse(raw);
            root.state = parsed;
            root.sessions = parsed.sessions ?? [];
            root.sessionCount = parsed.session_count ?? root.sessions.length;
            root.lastUpdatedAt = parsed.updated_at ?? "";
        } catch (error) {
            console.warn(`[Orbitbar] Failed to parse state file: ${error}`);
        }
    }

    function focusedSession() {
        return root.sessions.length > 0 ? root.sessions[0] : null;
    }

    Process {
        id: bridgeProcess
        command: [
            "python",
            root.bridgeScriptPath,
            "--socket-path",
            root.socketPath,
            "--state-path",
            root.statePath,
        ]
        running: false
        onExited: (exitCode, exitStatus) => {
            console.log(`[Orbitbar] Bridge exited with code ${exitCode}`)
            if (root.daemonEnabled)
                restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.daemonEnabled && !bridgeProcess.running)
                bridgeProcess.running = true
        }
    }

    FileView {
        id: stateFile
        path: Qt.resolvedUrl(root.statePath)
        watchChanges: true
        blockLoading: true
        onLoaded: {
            root.parseState(stateFile.text())
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.resetState()
                stateFile.setText(JSON.stringify(root.state))
            } else {
                console.warn(`[Orbitbar] Failed to load state file: ${error}`)
            }
        }
    }
}
