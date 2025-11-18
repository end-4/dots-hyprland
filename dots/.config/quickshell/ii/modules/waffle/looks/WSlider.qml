pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets

Slider {
    id: root

    property real trackWidth: 4
    // leftPadding: handle.width / 2
    // rightPadding: handle.width / 2
    leftPadding: 0
    rightPadding: 0

    implicitHeight: handle.implicitHeight

    Behavior on value { // This makes the adjusted value (like volume) shift smoothly
        SmoothedAnimation {
            velocity: Looks.transition.velocity
        }
    }

    background: Item {
        id: background
        anchors.fill: parent

        Rectangle {
            id: trackHighlight
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            topLeftRadius: root.trackWidth / 2
            bottomLeftRadius: root.trackWidth / 2
            color: Looks.colors.accent
            implicitHeight: root.trackWidth
            width: background.width * root.visualPosition
        }

        Rectangle {
            id: trackTrough
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            topLeftRadius: root.trackWidth / 2
            bottomLeftRadius: root.trackWidth / 2
            color: Looks.colors.controlBg
            implicitHeight: root.trackWidth
            width: background.width * (1 - root.visualPosition)
        }
    }

    handle: Circle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        x: (diameter / 2) + root.visualPosition * (root.width - diameter) - (diameter / 2)
        diameter: 20
        color: Looks.colors.controlFg

        MouseArea {
            id: handleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Circle {
            anchors.centerIn: parent
            diameter: root.pressed ? 10 : handleMouseArea.containsMouse ? 14 : 12
            color: Looks.colors.accent

            Behavior on diameter {
                animation: Looks.transition.enter.createObject(this)
            }
        }
    }
}
