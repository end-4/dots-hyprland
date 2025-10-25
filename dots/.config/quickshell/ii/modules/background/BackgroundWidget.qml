import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: widgetRoot

    property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    
    signal rightClicked()
    signal middleClicked()

    property real scaleMultiplier: 1
    onScaleMultiplierChanged: {
        scale = scaleMultiplier
    }

    property bool lockPosition: false

    Drag.active: dragArea.drag.active

    Behavior on x { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on y { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on scale { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: lockPosition ? undefined : parent

        property bool dragActive: drag.active
        property bool down: false
        
        cursorShape: down ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        drag.minimumX: - implicitWidth / 2 - wallpaper.x
        drag.maximumX: monitor.width - widgetRoot.implicitWidth - wallpaper.x
        drag.minimumY: - implicitHeight / 2 - wallpaper.y
        drag.maximumY: monitor.height - widgetRoot.implicitHeight - wallpaper.y

        onPressed: (mouse) => {
            if (mouse.button == Qt.LeftButton && widgetRoot.lockPosition) return
            down = true
            widgetRoot.scale = scaleMultiplier * 1.07
            widgetRoot.opacity = 0.8
            
        }
        onReleased: (mouse) => {
            if (mouse.button == Qt.LeftButton && widgetRoot.lockPosition) return
            down = false
            widgetRoot.scale = scaleMultiplier * 1.0
            widgetRoot.opacity = 1.0
            
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton){
                widgetRoot.rightClicked()
            }
            if (mouse.button === Qt.MiddleButton){
                widgetRoot.middleClicked()
            }
        }
        onDragActiveChanged: {
            if (!dragActive) widgetRoot.savePosition(widgetRoot.x, widgetRoot.y) // saving position to config after dragging
        }
    }
}