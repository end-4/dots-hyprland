import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real widthRatio: {
        const widgetWidth = widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width;
        const monitorWidth = monitorData.transform & 1 ? monitorData.height : monitorData.width;
        (widgetWidth * monitorData.scale) / (monitorWidth * widgetMonitor.scale);
    }
    property real heightRatio: {
        const widgetHeight = widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height;
        const monitorHeight = monitorData.transform & 1 ? monitorData.width : monitorData.height;
        (widgetHeight * monitorData.scale) / (monitorHeight * widgetMonitor.scale);
    }
    property real initX: {
        Math.max((windowData?.at[0] - (monitorData?.x ?? 0) - monitorData?.reserved[0]) * widthRatio * root.scale, 0) + xOffset;
    }

    property real initY: {
        Math.max((windowData?.at[1] - (monitorData?.y ?? 0) - monitorData?.reserved[1]) * heightRatio * root.scale, 0) + yOffset;
    }
    property real xOffset: 0
    property real yOffset: 0
    property var widgetMonitor
    property int widgetMonitorId: widgetMonitor.id

    property var targetWindowWidth: windowData?.size[0] * scale * widthRatio
    property var targetWindowHeight: windowData?.size[1] * scale * heightRatio
    property bool hovered: false
    property bool pressed: false

    property var iconToWindowRatio: 0.35
    property var xwaylandIndicatorToIconRatio: 0.35
    property var iconToWindowRatioCompact: 0.6
    property var iconPath: Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing")
    property bool compactMode: Appearance.font.pixelSize.smaller * 4 > targetWindowHeight || Appearance.font.pixelSize.smaller * 4 > targetWindowWidth

    property bool indicateXWayland: windowData?.xwayland ?? false

    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    opacity: windowData.monitor == widgetMonitorId ? 1 : 0.4

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: Appearance.rounding.windowRounding * root.scale
        }
    }

    Behavior on x {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on width {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on height {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: GlobalStates.overviewOpen ? root.toplevel : null
        live: true

        // Color overlay for interactions
        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.windowRounding * root.scale
            color: pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : 
                hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : 
                ColorUtils.transparentize(Appearance.colors.colLayer2)
            border.color : ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.7)
            border.width : 1
        }

        Image {
            id: windowIcon
            anchors.centerIn: parent
            property var iconSize: {
                // console.log("-=-=-", root.toplevel.title, "-=-=-")
                // console.log("Target window size:", targetWindowWidth, targetWindowHeight)
                // console.log("Icon ratio:", root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)
                // console.log("Scale:", root.monitorData.scale)
                // console.log("Final:", Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio) / root.monitorData.scale)
                return Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio);
            }
            // mipmap: true
            Layout.alignment: Qt.AlignHCenter
            source: root.iconPath
            width: iconSize
            height: iconSize
            sourceSize: Qt.size(iconSize, iconSize)

            Behavior on width {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
            Behavior on height {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }
    }
}
