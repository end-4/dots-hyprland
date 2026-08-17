import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    property bool alttabOpen: false
    property int currentIndex: 0
    property var currentToplevel: null
    readonly property var allToplevels: ToplevelManager.toplevels.values
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var activeWorkspace: HyprlandData.activeWorkspace ?? focusedMonitor?.activeWorkspace ?? null
    readonly property var activeWindowWorkspaceId: HyprlandData.clientForToplevel(ToplevelManager.activeToplevel)?.workspace?.id ?? activeWorkspace?.id ?? -1
    readonly property var activeSpecialWorkspace: root.monitors.find(m => m.name === root.focusedMonitor?.name)?.specialWorkspace ?? null
    readonly property bool specialWorkspaceActive: activeWindowWorkspaceId < 0
    readonly property int currentWorkspaceId: root.activeWindowWorkspaceId
    readonly property int toplevelCount: filteredToplevels.length

    readonly property var windowByAddress: HyprlandData.windowByAddress
    readonly property var monitors: HyprlandData.monitors

    function workspaceIdForToplevel(toplevel) {
        return HyprlandData.clientForToplevel(toplevel)?.workspace?.id ?? -1
    }
    readonly property var filteredToplevels: {
        const workspaceId = root.currentWorkspaceId
        if (workspaceId === -1) return []
        return root.allToplevels.filter(toplevel => root.workspaceIdForToplevel(toplevel) === workspaceId)
    }
    function showEmpty(): void {
        if (!windowLoader.active) windowLoader.active = true
        root.alttabOpen = true
        root.currentToplevel = null
        root.currentIndex = 0
        GlobalStates.alttabReleaseMightTrigger = true
    }
    readonly property var visibleToplevels: {
        const arr = root.filteredToplevels
        const count = Math.min(4, arr.length)
        const result = []
        for (let i = 0; i < count; i++)
            result.push(arr[(root.currentIndex + i) % arr.length])
        return result
    }

    GlobalShortcut {
        name: "alttabShow"
        description: "Shows alt-tab selector on Alt+Tab press"

        onPressed: {
            if (!Config.options.alttab.enable) return
            const toplevels = root.filteredToplevels
            if (toplevels.length === 0) {
                root.showEmpty()
                return
            }
            if (!root.alttabOpen) {
                if (!windowLoader.active) windowLoader.active = true
                const activeIndex = toplevels.indexOf(ToplevelManager.activeToplevel)
                root.currentIndex = activeIndex >= 0 ? (activeIndex + 1) % toplevels.length : 0
                root.currentToplevel = toplevels[root.currentIndex]
                root.alttabOpen = true
                GlobalStates.alttabReleaseMightTrigger = true
                return
            }
            root.currentIndex = (root.currentIndex + 1) % toplevels.length
            root.currentToplevel = toplevels[root.currentIndex]
        }
    }


    GlobalShortcut {
        name: "alttabCyclePrev"
        description: "Cycles to previous window on Shift+Tab"

        onPressed: {
            if (!root.alttabOpen) return
            const toplevels = root.filteredToplevels
            if (toplevels.length === 0) return
            root.currentIndex = (root.currentIndex - 1 + toplevels.length) % toplevels.length
            root.currentToplevel = toplevels[root.currentIndex]
        }
    }

    GlobalShortcut {
        name: "alttabRelease"
        description: "Commits focus on Alt+Tab release"

        onReleased: {
            if (!root.alttabOpen) return
            if (!GlobalStates.alttabReleaseMightTrigger) {
                GlobalStates.alttabReleaseMightTrigger = true
                return
            }
            if (root.currentToplevel !== null && root.currentToplevel !== undefined) {
                const addr = `0x${root.currentToplevel.HyprlandToplevel?.address}`
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`)
            }
            root.alttabOpen = false
            root.currentToplevel = null
            root.currentIndex = 0
            GlobalStates.alttabReleaseMightTrigger = true
        }
    }
    GlobalShortcut {
        name: "alttabCancel"
        description: "Cancels Alt-Tab without changing focus"

        onPressed: {
            root.alttabOpen = false
            root.currentToplevel = null
            root.currentIndex = 0
            GlobalStates.alttabReleaseMightTrigger = false
        }
    }


    LazyLoader {
        id: windowLoader
        component: AltTabWindow { service: root }
    }

    IpcHandler {
        target: "alttab"
        function open(): void {
            if (!Config.options.alttab.enable) return
            if (!windowLoader.active) windowLoader.active = true
            root.alttabOpen = true
            GlobalStates.alttabReleaseMightTrigger = true
            if (root.currentToplevel === null || root.currentToplevel === undefined) {
                root.currentIndex = 0
                root.currentToplevel = root.filteredToplevels[0] ?? null
            }
        }

        function close(): void {
            root.alttabOpen = false
            root.currentToplevel = null
            root.currentIndex = 0
        }
    }
        function cycle(): void {
            const toplevels = root.filteredToplevels
            if (toplevels.length === 0) {
                root.showEmpty()
                return
            }
            if (!root.alttabOpen) {
                if (!windowLoader.active) windowLoader.active = true
                root.alttabOpen = true
                root.currentIndex = 0
                root.currentToplevel = toplevels[0]
            } else {
                root.currentIndex = (root.currentIndex + 1) % toplevels.length
                root.currentToplevel = toplevels[root.currentIndex]
            }
        }

        function cyclePrev(): void {
            const toplevels = root.filteredToplevels
            if (toplevels.length === 0) {
                root.showEmpty()
                return
            }
            if (!root.alttabOpen) {
                if (!windowLoader.active) windowLoader.active = true
                root.alttabOpen = true
                root.currentIndex = 0
                root.currentToplevel = toplevels[0]
            } else {
                root.currentIndex = (root.currentIndex - 1 + toplevels.length) % toplevels.length
                root.currentToplevel = toplevels[root.currentIndex]
            }
        }

        function cancel(): void {
            root.alttabOpen = false
            root.currentToplevel = null
            root.currentIndex = 0
            GlobalStates.alttabReleaseMightTrigger = false
        }

        function release(): void {
            if (!root.alttabOpen) return
            if (root.currentToplevel !== null && root.currentToplevel !== undefined) {
                const addr = `0x${root.currentToplevel.HyprlandToplevel?.address}`
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`)
            }
            root.alttabOpen = false
            root.currentToplevel = null
            root.currentIndex = 0
        }

    IpcHandler {
        target: "alttabKeys"
        function cycle(): void { root.cycle() }
        function cyclePrev(): void { root.cyclePrev() }
        function cancel(): void { root.cancel() }
        function release(): void { root.release() }
    }
}
