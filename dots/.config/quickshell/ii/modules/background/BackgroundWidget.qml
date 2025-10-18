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

    signal positionChanged(int newX, int newY)
    signal rightClicked()


    property real scaleMultiplier: 1
    onScaleMultiplierChanged: {
        scale = scaleMultiplier
    }
    property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

    Drag.active: dragArea.drag.active


    Behavior on x {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on scale {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: parent

        property bool down: false
        cursorShape: down ? Qt.ClosedHandCursor : undefined

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // better way??
        drag.minimumX: - implicitWidth / 2 - wallpaper.x
        drag.maximumX: monitor.width - widgetRoot.implicitWidth - wallpaper.x
        drag.minimumY: - implicitHeight / 2 - wallpaper.y
        drag.maximumY: monitor.height - widgetRoot.implicitHeight - wallpaper.y

        property bool dragActive: drag.active

        onPressed: {
            widgetRoot.scale = scaleMultiplier * 1.07
            widgetRoot.opacity = 0.8
            down = true
        }
        onReleased: {
            widgetRoot.scale = scaleMultiplier * 1.0
            widgetRoot.opacity = 1.0
            down = false
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton){
                widgetRoot.rightClicked()
            }
        }
        onDragActiveChanged: {
            if (!dragActive) widgetRoot.positionChanged(widgetRoot.x, widgetRoot.y)
        }
    }
}