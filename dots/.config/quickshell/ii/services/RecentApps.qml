pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tracks recently launched apps (by DesktopEntry id) and persists them
 * to disk, similar to how Config.qml persists shell options.
 */
Singleton {
    id: root

    property int maxStored: 20
    property int readWriteDelay: 50 // milliseconds

    // Resolves stored ids back to real DesktopEntry objects via AppSearch.list,
    // silently dropping any that no longer exist (e.g. app was uninstalled).
    function topEntries(count) {
        const ids = dataAdapter.recent.map(r => r.id);
        const resolved = [];
        for (const id of ids) {
            const entry = AppSearch.list.find(a => a.id === id);
            if (entry)
                resolved.push(entry);
            if (resolved.length >= count)
                break;
        }
        return resolved;
    }

    function recordUsage(id) {
        if (!id)
            return;
        const list = dataAdapter.recent.filter(r => r.id !== id);
        list.unshift({
            id: id,
            lastUsed: Date.now()
        });
        dataAdapter.recent = list.slice(0, root.maxStored);
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: fileView.writeAdapter()
    }

    FileView {
        id: fileView
        path: Directories.recentAppsPath
        watchChanges: true
        onAdapterUpdated: fileWriteTimer.restart()
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: dataAdapter
            property list<var> recent: []
        }
    }
}
