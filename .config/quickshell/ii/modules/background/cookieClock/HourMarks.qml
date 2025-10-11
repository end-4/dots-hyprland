pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    property real implicitSize: 135
    property real markLength: 10
    property color color: Appearance.colors.colOnSecondaryContainer
    property color colOnBackground: Appearance.colors.colSecondaryContainer

    property bool isEnabled: Config.options.background.clock.cookie.hourMarks

    Rectangle {
        opacity: root.isEnabled ? 1.0 : 0 
        z: 0
        color: root.color
        anchors.centerIn: parent
        implicitWidth: root.isEnabled ? root.implicitSize : root.implicitSize * 1.75
        implicitHeight: root.isEnabled ? root.implicitSize : root.implicitSize * 1.75 // Not using implicitHeight to allow smooth transition
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

    // Hour mark lines
    Rectangle {
        id: glowLines
        z: 1
        anchors.centerIn: parent
        Repeater {
            model: 12
            Item {
                required property int index
                anchors.fill: parent

                rotation: 360 / 12 * index 
                opacity: root.isEnabled ? 1.0 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.isEnabled ? 50 : 75
                    }
                    implicitWidth: root.markLength
                    implicitHeight: implicitWidth / 2 

                    radius: implicitWidth / 2
                    color: root.colOnBackground
                    opacity: root.isEnabled ? 0.5 : 0

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on anchors.leftMargin {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
        }
    }
}
