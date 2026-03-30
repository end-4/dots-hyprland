pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions

/**
 * Wallpaper Slideshow Service
 * Rotates wallpapers from a user-selected folder at a configurable interval.
 * Config is persisted via Config.options.wallpaperSlideshow (JsonObject).
 * Runs inside the Quickshell process — no separate autostart needed.
 */
Singleton {
    id: root

    // Bound to Config. Default values used until config is ready.
    property bool enabled: false
    property int intervalMinutes: 5
    property string folder: FileUtils.trimFileProtocol(Directories.pictures) + "/Wallpapers"

    // Status string for UI feedback
    property string statusMessage: ""

    // Internal: time until next change (seconds, counts down for UI)
    property int secondsRemaining: root.intervalMinutes * 60

    signal wallpaperChanged(string path)

    // ── Sync enabled ──────────────────────────────────────────────────────
    Binding on enabled {
        when: Config.ready
        value: Config.options.wallpaperSlideshow?.enabled ?? false
    }
    onEnabledChanged: {
        if (Config.ready) Config.options.wallpaperSlideshow.enabled = root.enabled
        if (root.enabled) {
            slideshowTimer.restart()
            countdownTimer.restart()
            root.secondsRemaining = root.intervalMinutes * 60
            root.statusMessage = "Running"
        } else {
            slideshowTimer.stop()
            countdownTimer.stop()
            root.statusMessage = "Stopped"
        }
    }

    // ── Sync intervalMinutes ─────────────────────────────────────────────
    Binding on intervalMinutes {
        when: Config.ready
        value: Config.options.wallpaperSlideshow?.intervalMinutes ?? 5
    }
    onIntervalMinutesChanged: {
        if (Config.ready) Config.options.wallpaperSlideshow.intervalMinutes = root.intervalMinutes
        slideshowTimer.interval = root.intervalMinutes * 60 * 1000
        root.secondsRemaining = root.intervalMinutes * 60
    }

    // ── Sync folder ───────────────────────────────────────────────────────
    Binding on folder {
        when: Config.ready
        value: Config.options.wallpaperSlideshow?.folder ?? (FileUtils.trimFileProtocol(Directories.pictures) + "/Wallpapers")
    }
    onFolderChanged: {
        if (Config.ready) Config.options.wallpaperSlideshow.folder = root.folder
        Wallpapers.setDirectory(root.folder)
    }

    // ── Slideshow timer ───────────────────────────────────────────────────
    Timer {
        id: slideshowTimer
        interval: root.intervalMinutes * 60 * 1000
        repeat: true
        running: root.enabled
        onTriggered: {
            root.applyRandom()
            root.secondsRemaining = root.intervalMinutes * 60
        }
    }

    // ── Countdown timer (1 s tick for UI display) ─────────────────────────
    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.enabled
        onTriggered: {
            if (root.secondsRemaining > 0) root.secondsRemaining -= 1
        }
    }

    // ── Restore state when config is ready ────────────────────────────────
    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return
            // Ensure the wallpaperSlideshow key block exists in config
            if (!Config.options.wallpaperSlideshow) {
                Config.options.wallpaperSlideshow = {
                    enabled: false,
                    intervalMinutes: 5,
                    folder: root.folder
                }
            }
            root.enabled = Config.options.wallpaperSlideshow.enabled ?? false
            root.intervalMinutes = Config.options.wallpaperSlideshow.intervalMinutes ?? 5
            root.folder = Config.options.wallpaperSlideshow.folder ?? root.folder
            // Set wallpaper directory
            Wallpapers.setDirectory(root.folder)
        }
    }

    // ── Public API ────────────────────────────────────────────────────────
    function applyRandom() {
        Wallpapers.randomFromCurrentFolder()
        root.statusMessage = Qt.formatDateTime(new Date(), "Last changed: hh:mm:ss")
        root.wallpaperChanged(Wallpapers.effectiveDirectory)
    }

    function skipToNext() {
        root.applyRandom()
        // Reset the timer so the interval resets from now
        slideshowTimer.restart()
        countdownTimer.restart()
        root.secondsRemaining = root.intervalMinutes * 60
    }

    function setFolder(path) {
        root.folder = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
    }

    // Expose formatted countdown for UI
    readonly property string countdownText: {
        const m = Math.floor(root.secondsRemaining / 60)
        const s = root.secondsRemaining % 60
        return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
    }
}
