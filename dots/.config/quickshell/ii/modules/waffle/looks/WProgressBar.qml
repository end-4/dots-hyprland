pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

ProgressBar {
    id: root

    Behavior on value {
        SmoothedAnimation {
            velocity: Looks.transition.velocity
        }
    }

    implicitHeight: 4
    background: null
    
    contentItem: Item {
        id: background

        Rectangle {
            id: trackTrough
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            radius: root.implicitHeight / 2
            color: Looks.colors.controlBg
            implicitHeight: root.implicitHeight
        }

        Rectangle {
            id: trackHighlight
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            radius: root.implicitHeight / 2
            color: Looks.colors.accent
            implicitHeight: root.implicitHeight
            width: background.width * root.value
        }
    }
}
