pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    anchors.fill: parent

    required property int clockHour
    required property int clockMinute
    property real handWidth: 16
    property string style: "fill"
    property color color: Appearance.colors.colPrimary
    
    rotation: -90 + (360 / 12) * (root.clockHour + root.clockMinute / 60)
    z: root.style === "fill" ? 3 : 1

    opacity: root.style === "hide" ? 0.0 : 1.0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: {
            let position = parent.width / 2 - handWidth / 2;
            if (root.style === "classic") position -= 15;
            return position;
        }
        width: hourHandLength
        height: root.style === "classic" ? 8 : handWidth

        radius: root.style === "classic" ? 2 : handWidth / 2
        color : root.style === "stroke" ? "transparent" : root.color

        border.color: root.color
        border.width: 4
        

        Behavior on x {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}
