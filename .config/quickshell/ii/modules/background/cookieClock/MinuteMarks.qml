pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    Repeater {
        model: 12
        Item {
            required property int index
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "dots" ? 1.0 : 0
            rotation: 360 / 12 * index 
            anchors.fill: parent
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "dots" ? 10 : 50
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                implicitWidth: root.hourDotSize
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: root.colOnBackground
                opacity: 0.5
            }
        }
    }

    // Hour Indicator numbers (3-6-9-12)
    Repeater {
        model: 4
        Item {
            required property int index
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "numbers" ? 1.0 : 0 
            rotation: 360 / 4 * index 
            anchors.fill: parent
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                color: "transparent"
                implicitWidth: root.hourNumberSize
                implicitHeight: implicitWidth
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "numbers" ? 32 : 96
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                StyledText {
                    color: root.colOnBackground
                    anchors.centerIn: parent
                    text: index === 0 ? "9" : 
                        index === 1 ? "12" : 
                        index === 2 ? "3" : "6"
                    rotation: index % 2 === 0 ? index * 90 : -index * 90 //A better way can be found to show texts on right angle
                    font {
                        family: Appearance.font.family.reading
                        pixelSize: 80
                        weight: 1000
                    }
                }
            }
        }
    }

    // Full dial style hour lines
    Repeater {
        model: 12
        Item {
            required property int index
            rotation: 360 / 12 * index 
            anchors.fill: parent
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                implicitWidth: root.hourLineSize * 3.5
                implicitHeight: root.hourLineSize
                radius: implicitWidth / 2
                color: root.colOnBackground
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 10 : 50
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
    // Full dial style minute lines
    Repeater {
        model: 60
        Item {
            required property int index
            rotation: 360 / 60 * index 
            anchors.fill: parent
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                implicitWidth: root.minuteLineSize * 3.5
                implicitHeight: root.minuteLineSize
                radius: implicitWidth / 2
                color: root.colOnBackground
                opacity: 0.5
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 10 : 50
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
