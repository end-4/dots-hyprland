import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.background.widgets.cookieClock


Item {
    id: widgetRoot

    signal rightClicked()
    signal middleClicked()
    signal setPosToLeastBusy()

    property string widgetPrefix: ""

    function isWallpaperVideo(path) {
        return [".mp4", ".webm", ".mkv", ".avi", ".mov"].some(ext => path.endsWith(ext))
    }

    property bool wallpaperIsVideo: isWallpaperVideo(Config.options.background.wallpaperPath)
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    property var collectorData: {
        "position_x": 0,
        "position_y": 0,
        "dominant_color": Appearance.colors.colPrimary
    }

    property string leastBusyPlacedWidget: Config.options.background.widgets.leastBusyPlacedWidget
    onLeastBusyPlacedWidget: {
        updateLeastBusyRegion()
    }

    

    property real scaleMultiplier: 1
    onScaleMultiplierChanged: {
        scale = scaleMultiplier
    }

    property bool leastBusyMode: Config.options.background.widgets.leastBusyPlacedWidget === widgetPrefix 
    property bool lockPosition: false
    Drag.active: dragArea.drag.active

    onWallpaperPathChanged: updateLeastBusyRegion()
    Component.onCompleted: updateLeastBusyRegion()

    function updateLeastBusyRegion() {
        if (!leastBusyMode) return
        leastBusyRegion.update();
    }

    LeastBusyRegion {
        id: leastBusyRegion
        onGotLeastBusyData: {
            widgetRoot.collectorData = leastBusyRegion.collectorData
            widgetRoot.setPosToLeastBusy()
        }
    }

    Behavior on x { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on y { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on scale { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: lockPosition || leastBusyMode ? undefined : parent

        property bool dragActive: drag.active
        property bool down: false
        
        cursorShape: down ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        drag.minimumX: - implicitWidth / 2 - wallpaper.x
        drag.maximumX: monitor.width - widgetRoot.implicitWidth - wallpaper.x
        drag.minimumY: - implicitHeight / 2 - wallpaper.y
        drag.maximumY: monitor.height - widgetRoot.implicitHeight - wallpaper.y

        function setDragState(active) {
            down = active
            widgetRoot.scale = scaleMultiplier * (active ? 1.07 : 1.0)
            widgetRoot.opacity = active ? 0.8 : 1.0
        }

        onPressed: (mouse) => {
            if (mouse.button !== Qt.LeftButton || widgetRoot.lockPosition || widgetRoot.leastBusyMode) return
                setDragState(true)
        }
        onReleased: (mouse) => {
            if (mouse.button !== Qt.LeftButton) return
                setDragState(false)
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                widgetRoot.rightClicked()
            if (mouse.button === Qt.MiddleButton)
                widgetRoot.middleClicked()
        }
        onDragActiveChanged: {
            if (!dragActive) widgetRoot.savePosition()
        }
    }
}