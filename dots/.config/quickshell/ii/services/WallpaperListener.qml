pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.services

Singleton {
    id: root
    property var effectivePerMonitor: ({})

    // Bindings to watch config toggles for refresh
    readonly property bool multiMonitorEnabled: Config.options.background?.multiMonitor?.enable || false
    onMultiMonitorEnabledChanged: refresh()
    readonly property string globalWallpaperPath: Config.options.background?.wallpaperPath || ""
    onGlobalWallpaperPathChanged: refresh()
    readonly property var wallpapersByMonitorRef: Config.options.background?.wallpapersByMonitor || []
    onWallpapersByMonitorRefChanged: refresh()
    // Quickshell.screens seem to load images faster and does not compromise memory usage, can be reviewed further
    readonly property var screensRef: Quickshell.screens
    onScreensRefChanged: refresh()

    function refresh() {
        const result = {}
        const globalPath = globalWallpaperPath
        const byMonitorList = wallpapersByMonitorRef || []
        const screens = Quickshell.screens || []

        if (!root.multiMonitorEnabled) {
            for (let i = 0; i < screens.length; ++i) {
                const screen = screens[i]
                const monitor = Hyprland.monitorFor(screen)
                if (monitor && globalPath && globalPath.length > 0) {
                    result[monitor.name] = {
                        path: globalPath
                    }
                }
            }
            root.effectivePerMonitor = result
            return
        }

        const byMonitorMap = {}
        for (let i = 0; i < byMonitorList.length; ++i) {
            const entry = byMonitorList[i]
            if (entry && entry.monitor && entry.path) {
                const data = { path: entry.path }
                if (entry.startWorkspace !== undefined && entry.endWorkspace !== undefined) {
                    data.startWorkspace = entry.startWorkspace
                    data.endWorkspace = entry.endWorkspace
                }

                byMonitorMap[entry.monitor] = data
            }
        }

        for (let i = 0; i < screens.length; ++i) {
            const screen = screens[i]
            const monitor = Hyprland.monitorFor(screen)
            if (monitor) {
                const wallpaperData = byMonitorMap[monitor.name] || {
                    path: globalPath
                }
                if (wallpaperData.path && wallpaperData.path.length > 0) {
                    result[monitor.name] = wallpaperData
                }
            }
        }

        root.effectivePerMonitor = result
    }

    Component.onCompleted: refresh()
}
