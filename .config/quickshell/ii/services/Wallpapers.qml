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
 * switchwall.sh script. Pretty much a limited file browsing service.
 */
Singleton {
    id: root

    property string directory: FileUtils.trimFileProtocol(`${Directories.pictures}/Wallpapers`)
    readonly property list<string> extensions: [ // TODO: add videos
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"
    ]
    property alias filesModel: files // Expose for direct binding when needed
    property list<string> wallpapers: [] // List of absolute file paths (without file://)

    // Executions
    Process {
        id: applyProc
    }
    
    function openFallbackPicker() {
        applyProc.exec([Directories.wallpaperSwitchScriptPath])
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0) return
        applyProc.exec([
            Directories.wallpaperSwitchScriptPath,
            "--image", path,
            "--mode", (darkMode ? "dark" : "light")
        ])
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            validateDirProc.exec(["test", "-d", nicePath])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.directory = validateDirProc.nicePath
            }
        }
    }
    function setDirectory(path) {
        validateDirProc.setDirectoryIfValid(path)
    }

    // Folder model
    FolderListModel {
        id: files
        folder: Qt.resolvedUrl(root.directory)
        nameFilters: root.extensions.map(ext => `*.${ext}`)
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = []
            for (let i = 0; i < files.count; i++) {
                const path = files.get(i, "filePath") || FileUtils.trimFileProtocol(files.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
    }
}
