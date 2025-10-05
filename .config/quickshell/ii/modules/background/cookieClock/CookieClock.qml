pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: root

    readonly property string clockStyle: Config.options.background.clock.style

    property real implicitSize: 230
    property real hourHandLength: 72
    property real hourHandWidth: 20
    property real minuteHandLength: 95
    property real minuteHandWidth: Config.options.background.clock.cookie.minuteHandStyle === "bold" ? hourHandWidth :
                                    Config.options.background.clock.cookie.minuteHandStyle === "medium" ? 12 : 5
    property real centerDotSize: 10
    property real hourDotSize: 12
    property real centerGlowSize: 135
    property real secondDotSize: 20
    property real secondHandWidth: 2
    property real secondHandLength: 100
    property real hourLineSize: 5
    property real minuteLineSize: 2
    property real hourNumberSize: 36
    property real dateSquareSize: 64

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.5)
    property color colHourHand: Appearance.colors.colPrimary
    property color colMinuteHand: Appearance.colors.colSecondary
    property color colSecondHand: Appearance.colors.colTertiary
    property color colOnHourHand: Appearance.colors.colOnPrimary
    property color colTimeIndicators: Appearance.colors.colSecondaryContainerHover

    readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: DateTime.clock.minutes
    readonly property int clockSecond: DateTime.clock.seconds

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    DropShadow {
        source: cookie 
        anchors.fill: source
        horizontalOffset: 0
        verticalOffset: 2
        radius: 12
        samples: radius * 2 + 1
        color: root.colShadow
        transparentBorder: true
    }

    MaterialCookie {
        id: cookie
        z: 0
        implicitSize: root.implicitSize
        amplitude: implicitSize / 70
        sides: Config.options.background.clock.clockSides
        color: root.colBackground
        constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
    }

    // Hour dots dial style
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
                anchors{
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "dots" ? 10 : 50
                }
                Behavior on anchors.leftMargin{
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

    // Center glow lines
    Rectangle {
        id: glowLines
        z: 1
        anchors.centerIn: cookie
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

    // Numbers column
    Column {
        id: timeIndicators
        z: 1
        anchors.centerIn: cookie
        spacing: -16
        Repeater {
            model: root.clockNumbers
            delegate: StyledText {
                required property string modelData
                opacity: Config.options.background.clock.cookie.timeIndicators ? 1.0 : 0 // Not using visible to allow smooth transition
                anchors.horizontalCenter: parent?.horizontalCenter
                color: root.colOnBackground
                text: modelData.padStart(2, "0")
                font {
                    property real numberSizeWithoutGlow: modelData.match(/am|pm/i) ? 26 : 68
                    property real numberSizeWithGlow: modelData.match(/am|pm/i) ? 10 : 40
                    pixelSize: !Config.options.background.clock.cookie.timeIndicators ? 100 : // open/close animation
                                Config.options.background.clock.cookie.centerGlow ? numberSizeWithGlow : numberSizeWithoutGlow // changing size according to center glow
                    Behavior on pixelSize {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }
                    family: Appearance.font.family.expressive
                    weight: Font.Bold
                }
                Behavior on opacity { 
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }

    // Hour hand
    HourHand {
        anchors.fill: parent
        handWidth: root.hourHandWidth
        clockHour: root.clockHour
        clockMinute: root.clockMinute
        style: Config.options.background.clock.cookie.hourHandStyle
        color: root.colHourHand
    }

    // Minute hand
    MinuteHand {
        anchors.fill: parent
        handWidth: root.minuteHandWidth
        clockMinute: root.clockMinute
        style: Config.options.background.clock.cookie.minuteHandStyle
        color: root.colMinuteHand
    }

    // Second hand
    Loader {
        active: Config.options.time.secondPrecision && Config.options.background.clock.cookie.secondHandStyle !== "none"
        anchors.fill: parent
        sourceComponent: SecondHand {
            id: secondHand
            handWidth: root.secondHandWidth
            handLength: root.secondHandLength
            dotSize: root.secondDotSize
            clockSecond: root.clockSecond
            style: Config.options.background.clock.cookie.secondHandStyle
            color: root.colSecondHand
        }
    }

    // Center dot
    Rectangle {
        visible: Config.options.background.clock.cookie.minuteHandStyle === "hide" && Config.options.background.clock.cookie.hourHandStyle === "hide" ? false : true
        z: 4
        opacity: Config.options.background.clock.cookie.minuteHandStyle !== "bold" ? 1.0 : 0 
        color: Config.options.background.clock.cookie.minuteHandStyle === "medium" ? root.colBackground : root.colMinuteHand
        anchors.centerIn: parent
        implicitWidth: centerDotSize
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    // Center glow
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

    DateIndicator {
        anchors.fill: parent
        colOnBackground: root.colOnBackground
        style: Config.options.background.clock.cookie.dateStyle
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
                Behavior on anchors.leftMargin{
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                StyledText{
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
                Behavior on anchors.leftMargin{
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
                Behavior on anchors.leftMargin{
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
