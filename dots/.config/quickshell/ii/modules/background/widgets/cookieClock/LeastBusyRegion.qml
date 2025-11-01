import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    signal gotLeastBusyData()

    function isWallpaperVideo(path) {
        return [".mp4", ".webm", ".mkv", ".avi", ".mov"].some(ext => path.endsWith(ext))
    }
    property bool wallpaperIsVideo: isWallpaperVideo(Config.options.background.wallpaperPath)
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    property int widgetWidth: 10
    property int widgetHeight: 10

    property var collectorData: {
        "position_x": 0,
        "position_y": 0,
        "dominant_color": Appearance.colors.colPrimary
    }

    function update() {
        getLeastBusyRegionProc.running = true;
    }
    
    function handleProcessOutput(outputText) {
        if (!outputText || outputText.trim() === "") return
        const parsed = JSON.parse(outputText)

        collectorData = {
            position_x: parsed.center_x ?? 0,
            position_y: parsed.center_y ?? 0,
            dominant_color: parsed.dominant_color ?? Appearance.colors.colPrimary
        }
        
        gotLeastBusyData(collectorData)
    }

    Process {
        id: getLeastBusyRegionProc
        command: [
            Quickshell.shellPath("scripts/images/least-busy-region-venv.sh"),
            "--screen-width", 1920,
            "--screen-height", 1080,
            "--horizontal-padding", 100,
            "--vertical-padding", 100,
            "--width", widgetWidth,
            "--height", widgetHeight,
            root.wallpaperPath
        ]
        stdout: StdioCollector {
            id: positionCollector
            onStreamFinished: handleProcessOutput(text)
        }
    }
}