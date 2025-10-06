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

    required property int clockSecond
    property real handWidth: 2
    property real handLength: 100
    property real dotSize: 20
    property string style: "hide"
    property color color: Appearance.colors.colSecondary
    
    z: root.style === "line" ? 2 : 3
    rotation: (360 / 60 * clockSecond) + 90 // +90 degrees to align with minute hand
    opacity: root.style !== "hide" ? 1.0 : 0

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on rotation {
        enabled: Config.options.background.clock.cookie.constantlyRotate // Animating every second is expensive...
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Rectangle {
        implicitWidth: root.style === "dot" ? root.dotSize : root.handLength
        implicitHeight: root.style === "dot" ? root.dotSize : root.handWidth
        radius: root.style === "dot" ? implicitWidth / 2 : root.handWidth / 2
        color: root.color
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 10
        }
    }
    Rectangle {
        // Dot on the classic style
        opacity: root.style === "classic" ? 1.0 : 0.0
        implicitHeight: root.style === "classic" ? 14 : 0
        implicitWidth: root.style === "classic" ? 14 : 0
        color: root.color
        radius: Appearance.rounding.small
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 40
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}