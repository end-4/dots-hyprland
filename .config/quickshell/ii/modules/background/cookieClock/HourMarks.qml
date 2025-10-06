pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    Rectangle {
        opacity: Config.options.background.clock.cookie.centerGlow ? 1.0 : 0 
        z: 0
        color: root.colTimeIndicators
        anchors.centerIn: parent
        implicitWidth: Config.options.background.clock.cookie.centerGlow ? centerGlowSize : centerGlowSize * 1.75
        implicitHeight: Config.options.background.clock.cookie.centerGlow ? centerGlowSize : centerGlowSize * 1.75 // Not using implicitHeight to allow smooth transition
        radius: implicitWidth / 2
        Behavior on opacity {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }

    // Center glow lines
    Rectangle {
        id: glowLines
        z: 1
        anchors.centerIn: parent
        Repeater {
            model: 12
            Item {
                required property int index
                opacity: Config.options.background.clock.cookie.centerGlow ? 1.0 : 0
                rotation: 360 / 12 * index 
                anchors.fill: parent
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: Config.options.background.clock.cookie.centerGlow ? 50 : 75
                    }
                    implicitWidth: root.hourDotSize
                    implicitHeight: implicitWidth / 2 
                    radius: implicitWidth / 2
                    color: root.colOnBackground
                    opacity: Config.options.background.clock.cookie.centerGlow ? 0.5 : 0 
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on anchors.leftMargin{
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
        }
    }
}
