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

    // Monitor name -> workspace id to restore on unlock (set when locking)
    property var savedWorkspaces: ({})

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            var primaryName = Quickshell.primaryScreen?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
            var batch = ""
            // Process non-primary monitors first, then primary last so primary gets focus on unlock
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var screen = Quickshell.screens[j]
                if (screen.name === primaryName) continue
                var wsId = root.savedWorkspaces[screen.name]
                if (wsId !== undefined) {
                    batch += "dispatch focusmonitor " + screen.name + "; dispatch workspace " + wsId + "; "
                }
            }
            if (primaryName && root.savedWorkspaces[primaryName] !== undefined) {
                batch += "dispatch focusmonitor " + primaryName + "; dispatch workspace " + root.savedWorkspaces[primaryName] + "; "
            }
            if (batch.length > 0) {
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
            }
        }
    }

    lockSurface: LockSurface {
        context: root.context
    }

    // Defer lock workspace shuffle when Hyprland hasn't applied workspace bindings yet
    // (e.g. at session startup, second monitor may report workspace 0 until config is applied)
    Timer {
        id: deferLockTimer
        interval: 500
        repeat: false
        onTriggered: root.runLockWorkspaceShuffle()
    }

    function runLockWorkspaceShuffle() {
        var primaryName = Quickshell.primaryScreen?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
        var next = {}
        var batch = "keyword animation workspaces,1,7,menu_decel,slidevert; "
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var mon = Quickshell.screens[i].name
            if (mon === primaryName) continue
            var mData = HyprlandData.monitors.find(m => m.name === mon)
            var ws = Math.max(1, mData?.activeWorkspace?.id ?? 1)
            next[mon] = ws
            batch += "dispatch focusmonitor " + mon + "; dispatch workspace " + (2147483647 - ws) + "; "
        }
        if (primaryName) {
            var pData = HyprlandData.monitors.find(m => m.name === primaryName)
            var pWs = Math.max(1, pData?.activeWorkspace?.id ?? 1)
            next[primaryName] = pWs
            batch += "dispatch focusmonitor " + primaryName + "; dispatch workspace " + (2147483647 - pWs) + "; "
        }
        root.savedWorkspaces = next
        Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
    }

    function monitorsHaveInvalidWorkspace() {
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var mData = HyprlandData.monitors.find(m => m.name === Quickshell.screens[i].name)
            var ws = mData?.activeWorkspace?.id ?? 0
            if (ws < 1) return true
        }
        return false
    }

    // Single batch for lock and unlock so we don't race multiple hyprctl calls
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Lock: save workspace per monitor and move all to temp workspace in one batch.
                // If any monitor has workspace 0 (Hyprland not ready yet), reload config to apply
                // workspace bindings, then defer so Hyprland can update before we capture state.
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

    // Push everything down (visual only; workspace switch is in Connections above)
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
