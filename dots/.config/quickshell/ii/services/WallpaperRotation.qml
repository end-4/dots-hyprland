import QtQuick
import Qt.labs.folderlistmodel

// Kept independent of shell singletons so scheduling and selection can be tested.
Item {
    id: root
    visible: false

    required property url folder
    property url currentWallpaper
    property real intervalMinutes: 15
    property bool automaticEnabled: true
    property bool randomOnStartup: true
    property bool busy: false
    property bool paused: false
    property list<string> extensions: []
    readonly property int count: wallpaperModel.count
    property bool startupPending: automaticEnabled && randomOnStartup
    property bool requestPending: false

    onAutomaticEnabledChanged: startupPending = automaticEnabled && randomOnStartup

    // Coalesce rapid requests during a switch instead of launching competing theme processes.
    function requestRotation() {
        requestPending = true;
    }

    signal wallpaperSelected(path: string)

    // Pausing stops automatic timers; explicit user requests remain available.
    function rotate() {
        if (busy || wallpaperModel.status !== FolderListModel.Ready) return;
        const candidates = [];
        for (let i = 0; i < wallpaperModel.count; i++) {
            if (Qt.resolvedUrl(wallpaperModel.get(i, "filePath")).toString() !== Qt.resolvedUrl(currentWallpaper).toString()) {
                candidates.push(wallpaperModel.get(i, "filePath"));
            }
        }
        if (candidates.length === 0) return;
        wallpaperSelected(candidates[Math.floor(Math.random() * candidates.length)]);
    }

    FolderListModel {
        id: wallpaperModel
        // FolderListModel requires a file URL, even when settings store an absolute path.
        folder: Qt.resolvedUrl(root.folder)
        nameFilters: root.extensions.map(extension => `*.${extension}`)
        caseSensitive: false
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
    }

    Timer {
        interval: 0
        running: root.requestPending && !root.busy && wallpaperModel.status === FolderListModel.Ready && root.count > 0
        onTriggered: {
            root.requestPending = false;
            root.rotate();
        }
    }

    // Directory loading is asynchronous; do not consume the startup request early.
    Timer {
        interval: 0
        running: root.automaticEnabled && root.startupPending && !root.paused && !root.busy && wallpaperModel.status === FolderListModel.Ready && root.count > 0
        onTriggered: {
            root.startupPending = false;
            root.rotate();
        }
    }

    Timer {
        objectName: "rotationTimer"
        // QML timers use a signed 32-bit interval; the UI caps the value at one day.
        interval: Math.round(Math.max(1, Math.min(1440, root.intervalMinutes)) * 60000)
        repeat: true
        running: root.automaticEnabled && !root.startupPending && !root.paused && !root.busy && wallpaperModel.status === FolderListModel.Ready && root.count > 0
        onTriggered: root.rotate()
    }
}
