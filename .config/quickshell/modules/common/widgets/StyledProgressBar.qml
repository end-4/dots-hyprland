import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

ProgressBar {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4

    Behavior on value {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
    
    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Appearance.rounding.full
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        Rectangle { // Left progress fill
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Appearance.rounding.full
            color: Appearance.m3colors.m3primary
        }
        Rectangle { // Right remaining part fill
            anchors.right: parent.right
            width: (1 - root.visualPosition) * parent.width - valueBarGap
            height: parent.height
            radius: Appearance.rounding.full
            color: Appearance.m3colors.m3secondaryContainer
        }
        Rectangle { // Stop point
            anchors.right: parent.right
            width: valueBarGap
            height: valueBarGap
            radius: Appearance.rounding.full
            color: Appearance.m3colors.m3primary
        }
    }
}