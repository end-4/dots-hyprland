pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell.Hyprland

LockScreen {
    id: root

    // Monitor name -> { id, special } to restore on unlock
    property var savedWorkspaces: ({})

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            var primaryName = Quickshell.primaryScreen?.name
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")

            var batch = ""

            function restoreForMonitor(screenName) {
                var saved = root.savedWorkspaces[screenName]
                if (!saved) return

                batch += "dispatch focusmonitor " + screenName + "; "

                if (saved.special) {
                    batch += "dispatch togglespecialworkspace " + saved.special + "; "
                } else if (saved.id !== undefined) {
                    batch += "dispatch workspace " + saved.id + "; "
                }
            }

            // Non-primary first
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var screen = Quickshell.screens[j]
                if (screen.name === primaryName) continue
                restoreForMonitor(screen.name)
            }

            // Primary last (ensures focus)
            if (primaryName) {
                restoreForMonitor(primaryName)
            }

            if (batch.length > 0) {
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
            }
        }
    }

    lockSurface: LockSurface {
        context: root.context
    }

    Timer {
        id: deferLockTimer
        interval: 500
        repeat: false
        onTriggered: root.runLockWorkspaceShuffle()
    }

    function runLockWorkspaceShuffle() {
        var primaryName = Quickshell.primaryScreen?.name
            ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")

        var next = {}
        var batch = "keyword animation workspaces,1,7,menu_decel,slidevert; "

        function processMonitor(mon) {
            var mData = HyprlandData.monitors.find(m => m.name === mon)
            if (!mData || !mData.activeWorkspace) return false

            var wsId = Math.max(1, mData.activeWorkspace.id ?? 1)
            var wsName = mData.activeWorkspace.name ?? ""

            // Detect special workspace (Hyprland uses "special:<name>")
            var special = null
            if (wsName.startsWith("special:")) {
                special = wsName.substring(8)
            }

            next[mon] = {
                id: wsId,
                special: special
            }

            batch += "dispatch focusmonitor " + mon + "; "
            batch += "dispatch workspace " + (2147483647 - wsId) + "; "

            return true
        }

        // Non-primary first
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var mon = Quickshell.screens[i].name
            if (mon === primaryName) continue
            processMonitor(mon)
        }

        // Primary last
        if (primaryName) {
            processMonitor(primaryName)
        }

        root.savedWorkspaces = next

        Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
    }

    function monitorsHaveInvalidWorkspace() {
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var mData = HyprlandData.monitors.find(
                m => m.name === Quickshell.screens[i].name
            )
            var ws = mData?.activeWorkspace?.id ?? 0
            if (ws < 1) return true
        }
        return false
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                if (root.monitorsHaveInvalidWorkspace()) {
                    Quickshell.execDetached(["hyprctl", "reload"])
                    HyprlandData.updateAll()
                    deferLockTimer.start()
                } else {
                    root.runLockWorkspaceShuffle()
                }
            } else {
                restoreTimer.start()
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int verticalMovementDistance: modelData.height
            property int horizontalSqueeze: modelData.width * 0.2
        }
    }
}