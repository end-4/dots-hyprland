pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * YouTube Downloader Service
 * Wraps yt-dlp. Manages a download queue with progress tracking.
 * Requires: yt-dlp (install: yay -S yt-dlp)
 */
Singleton {
    id: root

    // ── Persisted config ──────────────────────────────────────────────────
    property string downloadPath: FileUtils.trimFileProtocol(Directories.home) + "/Downloads"
    property string quality: "best"   // "best" | "1080p" | "720p" | "480p" | "audio"
    property string format: "mp4"     // "mp4" | "mkv" | "webm" | "mp3" | "opus"
    property bool addMetadata: true

    // ── Queue ─────────────────────────────────────────────────────────────
    // Each item: { id, url, title, status, progress, error, outputPath }
    // status: "queued" | "downloading" | "done" | "error"
    property var queue: []
    property int _nextId: 0

    readonly property bool isDownloading: queue.some(item => item.status === "downloading")

    // ── Config sync ───────────────────────────────────────────────────────
    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return
            if (Config.options.ytDownloader) {
                root.downloadPath = Config.options.ytDownloader.downloadPath || root.downloadPath
                root.quality      = Config.options.ytDownloader.quality      || root.quality
                root.format       = Config.options.ytDownloader.format       || root.format
                root.addMetadata  = Config.options.ytDownloader.addMetadata  ?? true
            }
        }
    }

    function _saveConfig() {
        if (!Config.ready) return
        Config.options.ytDownloader = {
            downloadPath: root.downloadPath,
            quality:      root.quality,
            format:       root.format,
            addMetadata:  root.addMetadata
        }
    }

    onDownloadPathChanged: _saveConfig()
    onQualityChanged:      _saveConfig()
    onFormatChanged:       _saveConfig()
    onAddMetadataChanged:  _saveConfig()

    // ── Build yt-dlp command ──────────────────────────────────────────────
    function _buildCommand(url, itemId) {
        const qualityMap = {
            "best":   "bestvideo+bestaudio/best",
            "1080p":  "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
            "720p":   "bestvideo[height<=720]+bestaudio/best[height<=720]",
            "480p":   "bestvideo[height<=480]+bestaudio/best[height<=480]",
            "audio":  "bestaudio/best"
        }

        const formatArg = root.quality === "audio"
            ? ["--extract-audio", "--audio-format", root.format === "mp3" ? "mp3" : "opus"]
            : ["-f", qualityMap[root.quality] || "best", "--merge-output-format", root.format === "mp3" || root.format === "opus" ? "mp4" : root.format]

        const cmd = [
            "yt-dlp",
            "--newline",
            "--no-playlist",
            "-o", `${root.downloadPath}/%(title)s.%(ext)s`,
            ...formatArg
        ]

        if (root.addMetadata) cmd.push("--embed-metadata")
        cmd.push("--", url)
        return cmd
    }

    // ── Active processes (keyed by item id) ───────────────────────────────
    property var _procs: ({})

    // ── Public: add to queue and start ────────────────────────────────────
    function download(url) {
        if (!url || url.trim().length === 0) return

        const id = root._nextId++
        const item = { id, url: url.trim(), title: url.trim(), status: "queued", progress: 0, error: "", outputPath: "" }
        root.queue = [...root.queue, item]

        _startDownload(id)
    }

    function _updateItem(id, patch) {
        root.queue = root.queue.map(item => item.id === id ? Object.assign({}, item, patch) : item)
    }

    function _startDownload(id) {
        const item = root.queue.find(i => i.id === id)
        if (!item) return

        _updateItem(id, { status: "downloading", progress: 0 })

        const proc = _procComponent.createObject(root, { itemId: id, command: _buildCommand(item.url, id) })
        const procs = Object.assign({}, root._procs)
        procs[id] = proc
        root._procs = procs
        proc.running = true
    }

    // ── Actions ───────────────────────────────────────────────────────────
    function cancelDownload(id) {
        const proc = root._procs[id]
        if (proc) {
            proc.running = false
            proc.destroy()
            const procs = Object.assign({}, root._procs)
            delete procs[id]
            root._procs = procs
        }
        _updateItem(id, { status: "error", error: "Cancelled" })
    }

    function clearCompleted() {
        root.queue = root.queue.filter(item => item.status !== "done" && item.status !== "error")
    }

    function retryDownload(id) {
        _updateItem(id, { status: "queued", progress: 0, error: "" })
        _startDownload(id)
    }

    // ── Process component ─────────────────────────────────────────────────
    Component {
        id: _procComponent

        Process {
            property int itemId: -1

            stdout: SplitParser {
                onRead: data => {
                    // Parse [download] X% progress
                    const pctMatch = data.match(/\[download\]\s+([\d.]+)%/)
                    if (pctMatch) {
                        root._updateItem(itemId, { progress: parseFloat(pctMatch[1]) / 100 })
                    }
                    // Parse destination filename
                    const destMatch = data.match(/\[download\] Destination: (.+)/)
                    if (destMatch) {
                        root._updateItem(itemId, { outputPath: destMatch[1].trim() })
                    }
                    // Parse title from [youtube] line
                    const titleMatch = data.match(/\[(?:info|youtube|download)\].*?title[:\s]+(.+)/i)
                    if (titleMatch && titleMatch[1].trim().length > 0) {
                        root._updateItem(itemId, { title: titleMatch[1].trim() })
                    }
                    // Already downloaded
                    if (data.includes("[download] 100%") || data.includes("has already been downloaded")) {
                        root._updateItem(itemId, { progress: 1.0 })
                    }
                }
            }

            stderr: SplitParser {
                onRead: data => {
                    if (data.trim().length > 0) {
                        root._updateItem(itemId, { error: data.trim() })
                    }
                }
            }

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    root._updateItem(itemId, { status: "done", progress: 1.0 })
                } else {
                    const item = root.queue.find(i => i.id === itemId)
                    if (item && item.status !== "error") {
                        root._updateItem(itemId, { status: "error" })
                    }
                }
                const procs = Object.assign({}, root._procs)
                delete procs[itemId]
                root._procs = procs
                destroy()
            }
        }
    }
}
