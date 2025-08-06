import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    required property string iconName
    required property double percentage
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: resourceRowLayout.implicitHeight

    // Helper function to format KB to GB  
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB"
    }

    // Generate tooltip content based on resource type
    property string tooltipContent: {
        switch(iconName) {
            case "memory":
                return `Memory Usage
Used: ${formatKB(ResourceUsage.memoryUsed)}
Free: ${formatKB(ResourceUsage.memoryFree)}
Total: ${formatKB(ResourceUsage.memoryTotal)}
Usage: ${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
            case "swap_horiz":
                return ResourceUsage.swapTotal > 0 ? 
                    `Swap Usage
Used: ${formatKB(ResourceUsage.swapUsed)}
Free: ${formatKB(ResourceUsage.swapFree)}
Total: ${formatKB(ResourceUsage.swapTotal)}
Usage: ${Math.round(ResourceUsage.swapUsedPercentage * 100)}%` :
                    "Swap: Not configured"
            case "settings_slow_motion":
                return `CPU Usage
Current: ${Math.round(ResourceUsage.cpuUsage * 100)}%
Load: ${ResourceUsage.cpuUsage > 0.8 ? "High" : ResourceUsage.cpuUsage > 0.5 ? "Medium" : "Low"}`
            default:
                return "System Resource"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    LazyLoader {
        id: popupLoader
        active: mouseArea.containsMouse

        component: PopupWindow {
            id: popupWindow
            visible: true
            implicitWidth: resourcePopup.implicitWidth
            implicitHeight: resourcePopup.implicitHeight
            anchor.item: root
            anchor.edges: Edges.Top
            anchor.rect.x: (root.implicitWidth - popupWindow.implicitWidth) / 2
            anchor.rect.y: Config.options.bar.bottom ? 
                (-resourcePopup.implicitHeight - 15) :
                (root.implicitHeight + 15)
            color: "transparent"
            
            Rectangle {
                id: resourcePopup
                readonly property real margin: 10
                implicitWidth: popupText.implicitWidth + margin * 2
                implicitHeight: popupText.implicitHeight + margin * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                
                StyledText {
                    id: popupText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    text: tooltipContent
                }
            }
        }
    }

    RowLayout {
        spacing: 4
        id: resourceRowLayout
        x: shown ? 0 : -resourceRowLayout.width

        CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            lineWidth: 2
            value: percentage
            implicitSize: 26
            colSecondary: Appearance.colors.colSecondaryContainer
            colPrimary: Appearance.m3colors.m3onSecondaryContainer
            enableAnimation: false

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: iconName
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Appearance.colors.colOnLayer1
            text: `${Math.round(percentage * 100)}`
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}