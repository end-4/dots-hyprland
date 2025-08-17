import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Provides a list of wallpapers and an "apply" action that calls the existing
 * switchwall.sh script. Uses QML's built-in image scaling for thumbnails.
 */
Singleton {
    id: root

    // Directory to search for wallpapers (new location)
    // Resolves to: ~/Pictures/Wallpapers
    property list<string> searchDirs: [ FileUtils.trimFileProtocol(`${Directories.pictures}/Wallpapers`) ]

    // Supported image extensions. Videos are intentionally excluded for now
    // to keep the overview lightweight.
    readonly property list<string> extensions: [
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"
    ]

    // Resulting list of absolute file paths (without file:// prefix)
    property list<string> wallpapers: []

    // Public API (FolderListModel driven)
    function reload() {
        files.folder = `file://${root.searchDirs[0]}`
    }
    onSearchDirsChanged: reload()

    function apply(path) {
        if (!path || path.length === 0) return
        applyProc.command = [
            "bash", "-c",
            `${StringUtils.shellSingleQuoteEscape(Directories.wallpaperSwitchScriptPath)} ` +
            `--image ${StringUtils.shellSingleQuoteEscape(path)}`
        ]
        applyProc.running = true
    }

    // Folder model
    FolderListModel {
        id: files
        nameFilters: extensions.map(ext => `*.${ext}`)
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: true
        onCountChanged: {
            console.log(`[Wallpapers] FolderListModel count=${files.count} folder=${files.folder}`)
            root.wallpapers = []
            for (let i = 0; i < files.count; i++) {
                const path = files.get(i, "filePath") || FileUtils.trimFileProtocol(files.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
    }

    // Expose the model for direct binding when needed
    property alias filesModel: files

    // Internal: applying a wallpaper
    Process {
        id: applyProc
    }

    Component.onCompleted: reload()
}


