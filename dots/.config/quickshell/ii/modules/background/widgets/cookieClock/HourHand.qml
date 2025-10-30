pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick

Item {
    id: root

    required property int clockHour
    required property int clockMinute
    property real handLength: 72
    property real handWidth: 20
    property string style: "fill"
    property color color: Appearance.colors.colPrimary

    property real fillColorAlpha: root.style === "hollow" ? 0 : 1
    Behavior on fillColorAlpha {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    rotation: -90 + (360 / 12) * (root.clockHour + root.clockMinute / 60)
    Behavior on rotation {
        animation: RotationAnimation {
            direction: RotationAnimation.Clockwise
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (parent.width - root.handWidth) / 2 - 15 * (root.style === "classic")
        width: root.handLength
        height: root.style === "classic" ? 8 : root.handWidth
        radius: root.style === "classic" ? 2 : root.handWidth / 2
        color : Qt.rgba(root.color.r, root.color.g, root.color.b, root.fillColorAlpha)
        border.color: root.color
        border.width: 4

        Behavior on x {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}
