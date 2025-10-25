pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick

Item {
    id: root
    anchors.fill: parent

    required property int clockMinute
    property string style: "medium"
    property real handLength: 95
    property real handWidth: style === "bold" ? 18 : style === "medium" ? 12 : 5
    property color color: Appearance.colors.colSecondary

    rotation: -90 + (360 / 60) * root.clockMinute

    Behavior on rotation {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: {
            let position = parent.width / 2 - root.handWidth / 2;
            if (root.style === "classic") position -= 15;
            return position;
        }
        width: root.handLength
        height: root.handWidth
        
        radius: root.style === "classic" ? 2 : root.handWidth / 2
        color: Appearance.colors.colSecondary

        Behavior on height {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        Behavior on x {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}
