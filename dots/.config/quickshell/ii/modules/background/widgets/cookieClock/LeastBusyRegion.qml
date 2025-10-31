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

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    property int widgetWidth: 10
    property int widgetHeight: 10

    function update() {
        getLeastBusyRegionProc.running = true;
    }
    property var collectorData: {
        "position_x": 0,
        "position_y": 0,
        "dominant_color": Appearance.colors.colPrimary
    }

    Process {
        id: getLeastBusyRegionProc
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh"),"--screen-width", 1920, "--screen-height", 1080, "--horizontal-padding", 100, "--vertical-padding", 100 ,"--width", widgetWidth, "--height", widgetHeight, root.wallpaperPath
                ,]
        stdout: StdioCollector {
            id: positionCollector
            onStreamFinished: {
                if (this.text === "" || this.text == null) return;
                const output = this.text;
                const parsedContent = JSON.parse(output);
                var positionX = parsedContent.center_x;
                var positionY = parsedContent.center_y;
                var dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary; 
                collectorData = {
                    "position_x": positionX,
                    "position_y": positionY,
                    "dominant_color": dominantColor
                };
                gotLeastBusyData();
            }
        }
    }
}