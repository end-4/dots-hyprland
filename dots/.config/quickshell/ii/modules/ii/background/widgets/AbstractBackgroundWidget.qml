import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale
    property bool visibleWhenLocked: false
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    // Relative position 0-1: same relative spot on all monitors. Bounds use monitor resolution.
    property real targetX: {
        const useRel = configEntry.relX >= 0 && configEntry.relX <= 1 && configEntry.relY >= 0 && configEntry.relY <= 1;
        const maxX = Math.max(0, screenWidth - width);
        const maxY = Math.max(0, screenHeight - height);
        if (useRel) return Math.max(0, Math.min(configEntry.relX * maxX, maxX));
        return Math.max(0, Math.min(configEntry.x, maxX));
    }
    property real targetY: {
        const useRel = configEntry.relX >= 0 && configEntry.relX <= 1 && configEntry.relY >= 0 && configEntry.relY <= 1;
        const maxY = Math.max(0, screenHeight - height);
        if (useRel) return Math.max(0, Math.min(configEntry.relY * maxY, maxY));
        return Math.max(0, Math.min(configEntry.y, maxY));
    }
    x: targetX
    y: targetY
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free"
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    drag.target: draggable && !middleButtonPressed ? root : undefined
    property bool middleButtonPressed: false

    function centerHorizontally() {
        const centerX = (screenWidth - width) / 2;
        const maxX = Math.max(0, screenWidth - width);
        configEntry.x = Math.max(0, Math.min(centerX, maxX));
        configEntry.relX = 0.5;
    }

    onPressed: (event) => {
        if (event.button === Qt.MiddleButton) {
            middleButtonPressed = true;
            centerHorizontally();
            event.accepted = true;
        }
    }
    onReleased: (event) => {
        if (event.button === Qt.MiddleButton) {
            middleButtonPressed = false;
        }
        const px = root.x;
        const py = root.y;
        const maxX = Math.max(0, screenWidth - width);
        const maxY = Math.max(0, screenHeight - height);
        configEntry.x = px;
        configEntry.y = py;
        configEntry.relX = maxX > 0 ? Math.max(0, Math.min(1, px / maxX)) : 0.5;
        configEntry.relY = maxY > 0 ? Math.max(0, Math.min(1, py / maxY)) : 0.5;
    }

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }
    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        // TODO: make these less arbitrary
        property int contentWidth: 300
        property int contentHeight: 300
        property int horizontalPadding: 200
        property int verticalPadding: 200
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh") // Comments to force the formatter to break lines
            , "--screen-width", Math.round(root.screenWidth) //
            , "--screen-height", Math.round(root.screenHeight) //
            , "--width", contentWidth //
            , "--height", contentHeight //
            , "--horizontal-padding", horizontalPadding //
            , "--vertical-padding", verticalPadding //
            , wallpaperPath //
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
            // "--visual-output",
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                // console.log("[Background] Least busy region output:", output)
                if (output.length === 0) return;
                const parsedContent = JSON.parse(output);
                root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                if (root.placementStrategy === "free") return;
                // Script returns monitor-space coordinates (not wallpaper-space)
                const newX = parsedContent.center_x - root.width / 2;
                const newY = parsedContent.center_y - root.height / 2;
                const maxX = Math.max(0, root.screenWidth - root.width);
                const maxY = Math.max(0, root.screenHeight - root.height);
                const clampedX = Math.max(0, Math.min(newX, maxX));
                const clampedY = Math.max(0, Math.min(newY, maxY));
                root.configEntry.x = clampedX;
                root.configEntry.y = clampedY;
                root.configEntry.relX = maxX > 0 ? Math.max(0, Math.min(1, clampedX / maxX)) : 0.5;
                root.configEntry.relY = maxY > 0 ? Math.max(0, Math.min(1, clampedY / maxY)) : 0.5;
            }
        }
    }
}

