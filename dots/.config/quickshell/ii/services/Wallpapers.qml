import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Provides a list of wallpapers and an "apply" action that calls the existing
 * switchwall.sh script. Pretty much a limited file browsing service.
 */
Singleton {
    id: root

    property string thumbgenScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/thumbgen-venv.sh`
    property string generateThumbnailsMagickScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/generate-thumbnails-magick.sh`
    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(folderModel.folder.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.pictures}/Wallpapers`)
    property alias folderModel: folderModel // Expose for direct binding when needed
    property string searchQuery: ""
    readonly property list<string> extensions: [ // TODO: add videos
        "jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"
    ]
    property list<string> wallpapers: [] // List of absolute file paths (without file://)
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running
    property real thumbnailGenerationProgress: 0

    signal changed()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load () {} // For forcing initialization

    // Executions
    Process {
        id: applyProc
    }

    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode) {
        const args = [
            Directories.wallpaperSwitchScriptPath,
            "--mode", (darkMode ? "dark" : "light")
        ]

        if (Config.options.background?.multiMonitor?.enable) {
            const focusedMonitor = Hyprland.focusedMonitor?.name
            if (focusedMonitor) {
                args.push("--monitor", focusedMonitor)
            }
        }

        applyProc.exec(args)
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        if (!path || path.length === 0) return
        const args = [
            Directories.wallpaperSwitchScriptPath,
            "--image", path,
            "--mode", (darkMode ? "dark" : "light")
        ]
        if (monitorName !== "") {
            args.push("--monitor", monitorName)
        }
        applyProc.exec(args)
        root.changed()
    }

    Process {
        id: selectProc
        property string filePath: ""
        property bool darkMode: Appearance.m3colors.darkmode
        property string monitorName: ""
        function select(filePath, darkMode = Appearance.m3colors.darkmode, monitorName = "") {
            selectProc.filePath = filePath
            selectProc.darkMode = darkMode
            selectProc.monitorName = monitorName
            selectProc.exec(["test", "-d", FileUtils.trimFileProtocol(filePath)])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                setDirectory(selectProc.filePath);
                return;
            }
            root.apply(selectProc.filePath, selectProc.darkMode, selectProc.monitorName);
        }
    }

    function select(filePath, darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        selectProc.select(filePath, darkMode, monitorName);
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode, monitorName = "") {
        if (folderModel.count === 0) return;
        const randomIndex = Math.floor(Math.random() * folderModel.count);
        const filePath = folderModel.get(randomIndex, "filePath");
        print("Randomly selected wallpaper:", filePath);
        root.select(filePath, darkMode, monitorName);
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            if (/^\/*$/.test(validateDirProc.nicePath)) validateDirProc.nicePath = "/";
            validateDirProc.exec([
                "bash", "-c",
                `if [ -d "${validateDirProc.nicePath}" ]; then echo dir; elif [ -f "${validateDirProc.nicePath}" ]; then echo file; else echo invalid; fi`
            ])
        }
        stdout: StdioCollector {
            onStreamFinished: {
                    root.directory = Qt.resolvedUrl(validateDirProc.nicePath)
                const result = text.trim()
                if (result === "dir") {
                } else if (result === "file") {
                    root.directory = Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath))
                } else {
                    // Ignore
                }
            }
        }
    }
    function setDirectory(path) {
        validateDirProc.setDirectoryIfValid(path)
    }
    function navigateUp() {
        folderModel.navigateUp()
    }
    function navigateBack() {
        folderModel.navigateBack()
    }
    function navigateForward() {
        folderModel.navigateForward()
    }

    // Folder model
    FolderListModelWithHistory {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolder)
        caseSensitive: false
        nameFilters: root.extensions.map(ext => `*${searchQuery.split(" ").filter(s => s.length > 0).map(s => `*${s}*`)}*.${ext}`)
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = []
            for (let i = 0; i < folderModel.count; i++) {
                const path = folderModel.get(i, "filePath") || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
    }

    // Thumbnail generation
    function generateThumbnail(size: string) {
        // console.log("[Wallpapers] Updating thumbnails")
        if (!["normal", "large", "x-large", "xx-large"].includes(size)) throw new Error("Invalid thumbnail size");
        thumbgenProc.directory = root.directory
        thumbgenProc.running = false
        thumbgenProc.command = [
            "bash", "-c",
            `${thumbgenScriptPath} --size ${size} --machine_progress -d ${FileUtils.trimFileProtocol(root.directory)} || ${generateThumbnailsMagickScriptPath} --size ${size} -d ${root.directory}`,
        ]
        root.thumbnailGenerationProgress = 0
        thumbgenProc.running = true
    }
    Process {
        id: thumbgenProc
        property string directory
        stdout: SplitParser {
            onRead: data => {
                // print("thumb gen proc:", data)
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) {
                    const completed = parseInt(match[1])
                    const total = parseInt(match[2])
                    root.thumbnailGenerationProgress = completed / total
                }
                match = data.match(/FILE (.+)/)
                if (match) {
                    const filePath = match[1]
                    root.thumbnailGeneratedFile(filePath)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.thumbnailGenerated(thumbgenProc.directory)
        }
    }
}
