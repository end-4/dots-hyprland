import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

// Material 3 slider. See https://m3.material.io/components/sliders/overview
Slider {
    id: slider
    property real scale: 0.85
    property real backgroundDotSize: 4 * scale
    property real backgroundDotMargins: 4 * scale
    property real handleMargins: (slider.pressed ? 3 : 6) * scale
    property real handleWidth: (slider.pressed ? 3 : 5) * scale
    property real handleHeight: 44 * scale
    property real handleLimit: slider.backgroundDotMargins * scale
    property real trackHeight: 15 * scale
    property color highlightColor: Appearance.m3colors.m3primary
    property color trackColor: Appearance.m3colors.m3secondaryContainer
    property color handleColor: Appearance.m3colors.m3onSecondaryContainer

    property real limitedHandleRangeWidth: (slider.availableWidth - handleWidth - slider.handleLimit * 2)
    property string tooltipContent: `${Math.round(value * 100)}%`
    Layout.fillWidth: true
    from: 0
    to: 1

    Behavior on value { // This makes the adjusted value (like volume) shift smoothly
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
        }
    }

    Behavior on handleMargins {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        cursorShape: slider.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor 
    }

    background: Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: trackHeight
        
        // Fill left
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: slider.handleLimit + slider.visualPosition * slider.limitedHandleRangeWidth - (slider.handleMargins + slider.handleWidth / 2)
            height: trackHeight
            color: slider.highlightColor
            topLeftRadius: Appearance.rounding.full
            bottomLeftRadius: Appearance.rounding.full
            topRightRadius: Appearance.rounding.unsharpen
            bottomRightRadius: Appearance.rounding.unsharpen
        }

        // Fill right
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: slider.handleLimit + (1 - slider.visualPosition) * slider.limitedHandleRangeWidth - (slider.handleMargins + slider.handleWidth / 2)
            height: trackHeight
            color: slider.trackColor
            topLeftRadius: Appearance.rounding.unsharpen
            bottomLeftRadius: Appearance.rounding.unsharpen
            topRightRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
        }

        // Dot at the end
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: slider.backgroundDotMargins
            width: slider.backgroundDotSize
            height: slider.backgroundDotSize
            radius: Appearance.rounding.full
            color: slider.handleColor
        }
    }

    handle: Rectangle {
        id: handle
        x: slider.leftPadding + slider.handleLimit + slider.visualPosition * slider.limitedHandleRangeWidth
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: slider.handleWidth
        implicitHeight: slider.handleHeight
        radius: Appearance.rounding.full
        color: slider.handleColor

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        StyledToolTip {
            extraVisibleCondition: slider.pressed
            content: slider.tooltipContent
        }
    }
}