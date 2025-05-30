import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

/**
 * Material 3 progress bar. See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4
    property color highlightColor: Appearance?.colors.colPrimary ?? "#685496"
    property color trackColor: Appearance?.m3colors.m3secondaryContainer ?? "#F1D3F9"

    Behavior on value {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Appearance?.rounding.full ?? 9999
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        Rectangle { // Left progress fill
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Appearance?.rounding.full ?? 9999
            color: root.highlightColor
        }
        Rectangle { // Right remaining part fill
            anchors.right: parent.right
            width: (1 - root.visualPosition) * parent.width - valueBarGap
            height: parent.height
            radius: Appearance?.rounding.full ?? 9999
            color: root.trackColor
        }
        Rectangle { // Stop point
            anchors.right: parent.right
            width: valueBarGap
            height: valueBarGap
            radius: Appearance?.rounding.full ?? 9999
            color: root.highlightColor
        }
    }
}