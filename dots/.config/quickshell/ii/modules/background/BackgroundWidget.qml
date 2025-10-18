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

        // helpwanted
        // Not ideal, but keeps coordinates safe for now.
        drag.minimumX: 0
        drag.maximumX: monitor.width - parent.implicitWidth
        drag.minimumY: 0
        drag.maximumY: monitor.height - parent.implicitHeight 

        property bool dragActive: drag.active

        onPressed: {
            widgetRoot.scale = scaleMultiplier * 1.07
            widgetRoot.opacity = 0.8
        }
        onReleased: {
            widgetRoot.scale = scaleMultiplier * 1.0
            widgetRoot.opacity = 1.0
        }
        onDragActiveChanged: {
            if (!dragActive) widgetRoot.positionChanged(widgetRoot.x, widgetRoot.y)
        }
    }
}