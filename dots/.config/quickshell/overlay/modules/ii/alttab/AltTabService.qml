import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
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
    property var sourceWindowState: null
    property var sourceAddress: null
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

    function windowStateForToplevel(toplevel) {
        const client = HyprlandData.clientForToplevel(toplevel)
        return {
            internalFs: Number(client?.fullscreen ?? 0),
            clientFs: Number(client?.fullscreenClient ?? 0),
            floating: client?.floating === true,
            pinned: client?.pinned === true,
            pinFullscreened: client?.pinFullscreened === true
        }
    }

    function beginCycle() {
        const active = ToplevelManager.activeToplevel
        root.sourceAddress = active?.HyprlandToplevel?.address ? `0x${active.HyprlandToplevel.address}` : null
        root.sourceWindowState = active ? root.windowStateForToplevel(active) : null
    }

    function resetCycleState() {
        root.alttabOpen = false
        root.currentToplevel = null
        root.currentIndex = 0
        root.sourceWindowState = null
        root.sourceAddress = null
    }

    function focusWithSourceState(toplevel) {
        if (!toplevel) return
        const targetAddr = `0x${toplevel.HyprlandToplevel?.address ?? ""}`
        if (!targetAddr || targetAddr === "0x") return

        const source = root.sourceWindowState
        const targetState = root.windowStateForToplevel(toplevel)

        // 1. Focus target window
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${targetAddr}" })`)

        if (!source) return

        // 2. Restore source fullscreen/maximized state onto target
        if (source.internalFs !== targetState.internalFs || source.clientFs !== targetState.clientFs) {
            Hyprland.dispatch(`hl.dsp.window.fullscreen_state({ internal = ${source.internalFs}, client = ${source.clientFs}, action = "set", window = "address:${targetAddr}" })`)
        }

        // 3. Restore source floating state onto target
        if (source.floating !== targetState.floating) {
            const action = source.floating ? "enable" : "disable"
            Hyprland.dispatch(`hl.dsp.window.float({ action = "${action}", window = "address:${targetAddr}" })`)
        }

        // 4. Restore source pinned state onto target
        if (source.pinned !== targetState.pinned) {
            const action = source.pinned ? "enable" : "disable"
            Hyprland.dispatch(`hl.dsp.window.pin({ action = "${action}", window = "address:${targetAddr}" })`)
        }
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
    // This avoids allocating previews for off-screen windows.
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
                root.beginCycle()
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
                root.focusWithSourceState(root.currentToplevel)
            }
            root.resetCycleState()
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
                root.beginCycle()
                if (!windowLoader.active) windowLoader.active = true
                root.alttabOpen = true
                const activeIndex = toplevels.indexOf(ToplevelManager.activeToplevel)
                root.currentIndex = activeIndex >= 0 ? (activeIndex + 1) % toplevels.length : 0
                root.currentToplevel = toplevels[root.currentIndex]
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
                root.beginCycle()
                if (!windowLoader.active) windowLoader.active = true
                root.alttabOpen = true
                const activeIndex = toplevels.indexOf(ToplevelManager.activeToplevel)
                root.currentIndex = activeIndex >= 0 ? (activeIndex - 1 + toplevels.length) % toplevels.length : 0
                root.currentToplevel = toplevels[root.currentIndex]
            } else {
                root.currentIndex = (root.currentIndex - 1 + toplevels.length) % toplevels.length
                root.currentToplevel = toplevels[root.currentIndex]
            }
        }

        function cancel(): void {
            root.resetCycleState()
            GlobalStates.alttabReleaseMightTrigger = false
        }

        function release(): void {
            if (!root.alttabOpen) return
            if (root.currentToplevel !== null && root.currentToplevel !== undefined) {
                root.focusWithSourceState(root.currentToplevel)
            }
            root.resetCycleState()
        }

    IpcHandler {
        target: "alttabKeys"
        function cycle(): void { root.cycle() }
        function cyclePrev(): void { root.cyclePrev() }
        function cancel(): void { root.cancel() }
        function release(): void { root.release() }
    }
}
