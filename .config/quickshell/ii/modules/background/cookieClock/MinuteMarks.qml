pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root

    property int hourDotSize: 16
    property int hourNumberSize: 80
    property int hourLineSize: 8
    property int minuteLineSize: 4
    property color color: Appearance.colors.colOnSecondaryContainer
    property string style: Config.options.background.clock.cookie.dialNumberStyle // "dots", "numbers", "full", "hide"
    property string dateStyle : Config.options.background.clock.cookie.dateStyle 

    Repeater {
        model: 12
        Item {
            required property int index
            opacity: root.style === "dots" ? 1.0 : 0
            rotation: 360 / 12 * index 
            anchors.fill: parent
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.style === "dots" ? 10 : 50
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                implicitWidth: root.hourDotSize
                implicitHeight: implicitWidth
                radius: implicitWidth / 2
                color: root.color
                opacity: 0.5
            }
        }
    }

    // Hour Indicator numbers (3-6-9-12)
    Repeater {
        model: 4
        Item {
            id: numberItem
            required property int index
            opacity: root.style === "numbers" ? 1.0 : 0 
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
                    leftMargin: root.style === "numbers" ? root.dateStyle === "rotating" ? 48 : 32 : 96
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                StyledText {
                    color: root.color
                    anchors.centerIn: parent
                    text: numberItem.index === 0 ? "9" : 
                        numberItem.index === 1 ? "12" : 
                        numberItem.index === 2 ? "3" : "6"
                    rotation: numberItem.index % 2 === 0 ? numberItem.index * 90 : -numberItem.index * 90 //A better way can be found to show texts on right angle
                    font {
                        family: Appearance.font.family.reading
                        pixelSize: root.dateStyle === "rotating" ? 70 : 80
                        weight: 1000
                    }
                    Behavior on font.pixelSize {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
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
            opacity: root.style === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                implicitWidth: root.hourLineSize * 3.5
                implicitHeight: root.hourLineSize
                radius: implicitWidth / 2
                color: root.color
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.style === "full" ? 10 : 50
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
            opacity: root.style === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Rectangle {
                implicitWidth: root.minuteLineSize * 3.5
                implicitHeight: root.minuteLineSize
                radius: implicitWidth / 2
                color: root.color
                opacity: 0.5
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.style === "full" ? 10 : 50
                }
                Behavior on anchors.leftMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
