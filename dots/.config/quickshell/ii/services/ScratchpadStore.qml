pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string filePath: Directories.scratchpadPath
    property string metaPath: Directories.scratchpadMetaPath
    property string contents: ""
    property real minWidth: 320
    property real minHeight: 260
    property real width: 440
    property real height: 340

    function save(text) {
        root.contents = text
        scratchpadView.setText(root.contents)
    }

    function clampWidth(value) {
        const maxWidth = Math.max(minWidth, (Quickshell.primaryScreen?.width ?? 1920) * 0.7)
        return Math.min(Math.max(value, minWidth), maxWidth)
    }

    function clampHeight(value) {
        const maxHeight = Math.max(minHeight, (Quickshell.primaryScreen?.height ?? 1080) * 0.7)
        return Math.min(Math.max(value, minHeight), maxHeight)
    }

    function updateGeometry(newWidth, newHeight, persist) {
        const clampedWidth = clampWidth(newWidth)
        const clampedHeight = clampHeight(newHeight)
        let changed = false
        if (Math.abs(root.width - clampedWidth) > 0.5) {
            root.width = clampedWidth
            changed = true
        }
        if (Math.abs(root.height - clampedHeight) > 0.5) {
            root.height = clampedHeight
            changed = true
        }
        if (persist && changed) {
            saveGeometry(root.width, root.height)
        }
    }

    function refreshMeta() {
        scratchpadMetaView.reload()
    }

    function saveGeometry(newWidth, newHeight) {
        const clampedWidth = clampWidth(newWidth)
        const clampedHeight = clampHeight(newHeight)
        root.width = clampedWidth
        root.height = clampedHeight
        const payload = {
            width: root.width,
            height: root.height
        }
        scratchpadMetaView.setText(JSON.stringify(payload, null, 2))
    }

    function refresh() {
        scratchpadView.reload()
    }

    Component.onCompleted: {
        refresh()
        refreshMeta()
    }

    FileView {
        id: scratchpadView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            root.contents = scratchpadView.text()
            console.log("[Scratchpad] File loaded")
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                console.log("[Scratchpad] File not found, creating new file.")
                root.contents = ""
                scratchpadView.setText(root.contents)
            } else {
                console.log("[Scratchpad] Error loading file: " + error)
            }
        }
    }

    FileView {
        id: scratchpadMetaView
        path: Qt.resolvedUrl(root.metaPath)
        onLoaded: {
            try {
                const data = JSON.parse(scratchpadMetaView.text())
                const loadedWidth = parseFloat(data?.width)
                const loadedHeight = parseFloat(data?.height)
                root.updateGeometry(
                    isFinite(loadedWidth) ? loadedWidth : root.width,
                    isFinite(loadedHeight) ? loadedHeight : root.height,
                    false
                )
            } catch (err) {
                console.log("[Scratchpad] Failed to parse meta file:", err)
                root.saveGeometry(root.width, root.height)
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                console.log("[Scratchpad] Geometry meta not found, creating new file.")
                root.saveGeometry(root.width, root.height)
            } else {
                console.log("[Scratchpad] Error loading geometry meta:", error)
            }
        }
    }
}

