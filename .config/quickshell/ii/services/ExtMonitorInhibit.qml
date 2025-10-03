pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property bool hasExternalMonitor: false
    property bool extMonitorInhibit: Config.options?.monitors?.externalMonitorInhibit ?? false

    Timer {
        id: monitorChangeTimer
        interval: 250
        repeat: false
        onTriggered: {
            const newHasExternal = root.checkForExternalMonitor();
            console.log("Inhibit Status: " + extMonitorInhibit);
            console.log("Monitors Connected: " + Quickshell.screens.length);
            console.log("External Monitor Detected: " + newHasExternal);
            if (newHasExternal !== root.hasExternalMonitor) {
                root.hasExternalMonitor = newHasExternal;
                root.handleMonitorChange();
            }
        }
    }

    function checkForExternalMonitor() {
        const monitors = HyprlandData.monitors;

        // Look for common laptop screen patterns
        const builtInPatterns = [
        /^eDP/,     // Most common (eDP-1, eDP-2, etc.)
        /^LVDS/,    // Older laptops
        /^DSI/,     // Some newer laptops
        /^DP-\d+-\d+$/, // Some integrated displays
        ];

        const externalMonitors = monitors.filter(monitor => {
            return !builtInPatterns.some(pattern => pattern.test(monitor.name));
        });

        return externalMonitors.length > 0;
    }

    function handleMonitorChange() {
        if (!root.extMonitorInhibit) return;

        if (root.hasExternalMonitor && !Idle.inhibit) {
            Idle.toggleInhibit();
            console.log("[MonitorDetector] External monitor connected, enabling idle inhibitor");
        } else if (!root.hasExternalMonitor && Idle.inhibit) {
            Idle.toggleInhibit();
            console.log("[MonitorDetector] No external monitors, disabling idle inhibitor");
        }
    }

    property int monitorCount: Quickshell.screens.length
    onMonitorCountChanged: {
        monitorChangeTimer.restart();
    }

    property bool idleInhibitState: Idle.inhibit
    onIdleInhibitStateChanged: {
        if (root.extMonitorInhibit) {
            const shouldInhibit = root.hasExternalMonitor;
            if(Idle.inhibit !== shouldInhibit) {
                // Use a short timer to allow the UI to update, then override
                Qt.callLater(() => {
                    root.handleMonitorChange();
                });
            }
        }
    }

    Component.onCompleted: {
        root.hasExternalMonitor = root.checkForExternalMonitor();
    }

    function load() { }
}
