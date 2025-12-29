pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tracks application launch frequency for "frecency" search ranking.
 * Persists data to ~/.local/state/quickshell/user/app_usage.json
 */
Singleton {
    id: root

    property var launchCounts: ({})
    property real maxCount: 1
    property bool ready: false
    property bool writePending: false

    /**
     * Record an app launch - increments the count for the given app ID
     */
    function recordLaunch(appId: string) {
        if (!appId || appId.length === 0) return;
        
        const currentCount = root.launchCounts[appId] || 0;
        const newCount = currentCount + 1;
        
        // Update the counts object (need to reassign for change detection)
        let updated = Object.assign({}, root.launchCounts);
        updated[appId] = newCount;
        root.launchCounts = updated;
        
        // Update max for normalization
        if (newCount > root.maxCount) {
            root.maxCount = newCount;
        }
    }

    /**
     * Get normalized score (0-1) for an app based on launch frequency
     */
    function getScore(appId: string): real {
        if (!appId || appId.length === 0) return 0;
        const count = root.launchCounts[appId] || 0;
        if (count === 0 || root.maxCount === 0) return 0;
        return count / root.maxCount;
    }

    /**
     * Get raw launch count for an app
     */
    function getCount(appId: string): int {
        if (!appId || appId.length === 0) return 0;
        return root.launchCounts[appId] || 0;
    }

    // Persistence
    Timer {
        id: fileReloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            // Skip reload if a local write is pending to avoid losing changes
            if (!root.writePending) {
                usageFileView.reload();
            }
        }
    }

    Timer {
        id: fileWriteTimer
        interval: 500 // Slightly longer delay to batch rapid launches
        repeat: false
        onTriggered: {
            usageFileView.writeAdapter();
            root.writePending = false;
        }
    }

    // Trigger save when counts change
    onLaunchCountsChanged: {
        if (root.ready) {
            root.writePending = true;
            fileWriteTimer.restart();
        }
    }

    FileView {
        id: usageFileView
        path: Directories.appUsagePath

        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onLoaded: {
            // Recalculate maxCount from loaded data
            let max = 1;
            for (const appId in usageAdapter.counts) {
                if (usageAdapter.counts[appId] > max) {
                    max = usageAdapter.counts[appId];
                }
            }
            root.maxCount = max;
            root.launchCounts = usageAdapter.counts;
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.ready = true;
                fileWriteTimer.restart();
            } else {
                console.warn("AppUsage: Failed to load usage data:", error);
                root.ready = true;
            }
        }

        adapter: JsonAdapter {
            id: usageAdapter
            property var counts: root.launchCounts
        }
    }
}
