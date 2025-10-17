pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

Singleton {
    id: root
    property var effectivePerMonitor: ({})

    // Bindings to watch config toggles for refresh
    readonly property bool multiMonitorEnabled: Config.options.background?.multiMonitor?.enable || false
    onMultiMonitorEnabledChanged: scheduleRefresh()
    readonly property string globalWallpaperPath: Config.options.background?.wallpaperPath || ""
    onGlobalWallpaperPathChanged: scheduleRefresh()
    readonly property var wallpapersByMonitorRef: Config.options.background?.wallpapersByMonitor || []
    onWallpapersByMonitorRefChanged: scheduleRefresh()
    readonly property var hyprlandMonitorsRef: HyprlandData.monitors
    onHyprlandMonitorsRefChanged: scheduleRefresh()

    signal changed()

    Timer {
        id: debounce
        interval: 80
        repeat: false
        onTriggered: root.refresh()
    }

    function scheduleRefresh() {
        debounce.restart()
    }

    function refresh() {
        const result = {}
        const globalPath = globalWallpaperPath
        const byMonitorList = wallpapersByMonitorRef || []
        const monitors = HyprlandData.monitors || []

        if (!root.multiMonitorEnabled) {
            for (let i = 0; i < monitors.length; ++i) {
                const mon = monitors[i]
                if (globalPath && globalPath.length > 0) {
                    result[mon.name] = globalPath
                }
            }
            const oldJson = JSON.stringify(root.effectivePerMonitor)
            const newJson = JSON.stringify(result)
            if (oldJson !== newJson) {
                root.effectivePerMonitor = result
                root.changed()
            }
            return
        }

        const byMonitorMap = {}
        for (let i = 0; i < byMonitorList.length; ++i) {
            const entry = byMonitorList[i]
            if (entry && entry.monitor && entry.path) {
                byMonitorMap[entry.monitor] = entry.path
            }
        }

        for (let i = 0; i < monitors.length; ++i) {
            const mon = monitors[i]
            const path = byMonitorMap[mon.name] || globalPath
            if (path && path.length > 0) {
                result[mon.name] = path
            }
        }

        const oldJson = JSON.stringify(root.effectivePerMonitor)
        const newJson = JSON.stringify(result)
        if (oldJson !== newJson) {
            root.effectivePerMonitor = result
            root.changed()
        }
    }

    Component.onCompleted: refresh()
}
