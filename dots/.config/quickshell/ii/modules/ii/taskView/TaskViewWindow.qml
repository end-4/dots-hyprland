pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property real widthRatio: {
        const widgetWidth = widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width;
        const monitorWidth = monitorData.transform & 1 ? monitorData.height : monitorData.width;
        return (widgetWidth * monitorData.scale) / (monitorWidth * widgetMonitor.scale);
    }
    property real heightRatio: {
        const widgetHeight = widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height;
        const monitorHeight = monitorData.transform & 1 ? monitorData.width : monitorData.height;
        return (widgetHeight * monitorData.scale) / (monitorHeight * widgetMonitor.scale);
    }

    // Properties for smart packing layout
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0

    property var widgetMonitor
    property int widgetMonitorId: widgetMonitor.id

    property bool hovered: false
    property bool pressed: false

    property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing")

    // Animate position and size
    x: targetX
    y: targetY
    width: targetWidth
    height: targetHeight

    Behavior on x {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Rounded corners
    property real radius: Appearance.rounding.medium

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: GlobalStates.taskViewOpen ? root.toplevel : null
        live: true

        // Color overlay for interactions
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : "transparent"
            border.width: 0
        }

        Image {
            id: windowIcon
            property real iconSize: Math.min(root.width, root.height) * 0.2
            // Clamp icon size
            readonly property real finalIconSize: Math.max(32, Math.min(64, iconSize))

            anchors.centerIn: parent
            width: finalIconSize
            height: finalIconSize
            source: root.iconPath
            sourceSize: Qt.size(finalIconSize, finalIconSize)
            opacity: hovered ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: {
                GlobalStates.taskViewOpen = false;
                if (windowData) {
                    // Focus and bring window to top
                    Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                    Hyprland.dispatch("bringactivetotop");
                }
            }
        }
    }

    // Close Button
    RippleButton {
        id: closeButton
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 10
            rightMargin: 10
        }
        implicitWidth: 36
        implicitHeight: 36
        buttonRadius: Appearance.rounding.full
        // Always visible
        visible: true
        opacity: 1
        z: 10

        onClicked: {
            if (windowData) {
                Hyprland.dispatch(`closewindow address:${windowData.address}`);
            }
        }

        // Red background for close button
        Rectangle {
            anchors.fill: parent
            radius: parent.buttonRadius
            color: Appearance.colors.colError
            opacity: 0.8
        }

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            iconSize: 20
            text: "close"
            color: Appearance.colors.colOnError
        }
    }
}
