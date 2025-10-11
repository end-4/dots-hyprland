pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick

Item {
    id: root
    anchors.fill: parent

    required property int clockHour
    required property int clockMinute
    property real handLength: 72
    property real handWidth: 16
    property string style: "fill"
    property color color: Appearance.colors.colPrimary

    property real fillColorAlpha: root.style === "stroke" ? 0.0 : 1.0 // for animation
    Behavior on fillColorAlpha {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }
    

    rotation: -90 + (360 / 12) * (root.clockHour + root.clockMinute / 60)
    z: root.style === "fill" ? 3 : 1

    opacity: root.style === "hide" ? 0.0 : 1.0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: {
            let position = parent.width / 2 - root.handWidth / 2;
            if (root.style === "classic") position -= 15;
            return position;
        }
        width: root.handLength
        height: root.style === "classic" ? 8 : root.handWidth

        radius: root.style === "classic" ? 2 : root.handWidth / 2
        color : Qt.rgba(root.color.r, root.color.g, root.color.b, fillColorAlpha)

        border.color: root.color
        border.width: 4
        

        Behavior on x {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}
