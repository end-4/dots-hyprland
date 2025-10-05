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
    property real secondsHandWidth: 2
    property real secondsHandLength: 100
    property real hourLineSize: 5
    property real minuteLineSize: 2
    property real hourNumberSize: 36
    property real dateSquareSize: 64

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.5)
    property color colMinuteHand: Appearance.colors.colSecondary
    property color colHourHand: Appearance.colors.colPrimary
    property color colOnHourHand: Appearance.colors.colOnPrimary
    property color colTimeIndicators: Appearance.colors.colSecondaryContainerHover
    property color colSeconds: Appearance.colors.colTertiary

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
                    family: Appearance.font.family.main
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
        clockMinute: root.clockMinute
        style: Config.options.background.clock.cookie.minuteHandStyle
        color: root.colMinuteHand
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


    // Second hand/dot
    Item {
        id: secondHand
        z: Config.options.background.clock.cookie.secondHandStyle === "line" ? 2 : 3
        opacity: Config.options.background.clock.cookie.secondHandStyle !== "hide" ? 1.0 : 0
        rotation: (360 / 60 * clockSecond) + 90 // +90 degrees to align with minute hand
        anchors.fill: parent
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on rotation{
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Rectangle {
            implicitWidth: Config.options.background.clock.cookie.secondHandStyle === "dot" ? root.secondDotSize : root.secondsHandLength
            implicitHeight: Config.options.background.clock.cookie.secondHandStyle === "dot" ? root.secondDotSize : root.secondsHandWidth
            radius: Config.options.background.clock.cookie.secondHandStyle === "dot" ? implicitWidth / 2 : root.secondsHandWidth / 2
            color: colSeconds
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
        Rectangle{
            // Dot on the classic style
            opacity: Config.options.background.clock.cookie.secondHandStyle === "classic" ? 1.0 : 0.0
            implicitHeight: 14
            implicitWidth: 14
            color: root.colSeconds
            radius: Appearance.rounding.small
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 40
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    // Date (the rotating one with the second hand)
    Canvas {
        z: 0
        width: cookie.width
        height: cookie.height
        rotation: secondHand.rotation + 45  // +45 degrees to align with minute hand
        opacity: Config.options.background.clock.cookie.dateStyle === "rotating" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0,0,width,height);
            ctx.font = "700 30px " + Appearance.font.family.title;

            var text = DateTime.date.substring(0,3) + " " + DateTime.date.substring(4,7);
            var radius = 78;
            var angleStep = Math.PI / 2.35 / text.length;

            for (var i=0; i<text.length; i++) {
                var angle = i * angleStep - Math.PI/2;
                var x = width/2 + radius * Math.cos(angle);
                var y = height/2 + radius * Math.sin(angle);

                ctx.save();
                ctx.translate(x,y);
                ctx.rotate(angle + Math.PI/2);

                if (i >= 3)
                    ctx.fillStyle = root.colOnBackground;
                else
                    ctx.fillStyle = Appearance.colors.colSecondaryHover;

                ctx.fillText(text[i], 0, 0);
                ctx.restore();
            }
        }
    }

    // Date(only today's number) in right side of the clock
    Rectangle{
        z: 1
        implicitWidth: 45
        implicitHeight: Config.options.background.clock.cookie.dateStyle === "square" ? 30 : 0
        color: root.colOnBackground
        radius: Appearance.rounding.small
        anchors{
            verticalCenter: cookie.verticalCenter
            right: cookie.right
            rightMargin: 10
        }
        Behavior on implicitHeight{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText{
            opacity: Config.options.background.clock.cookie.dateStyle === "square" ? 1.0 : 0
            Behavior on opacity{
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            anchors.centerIn: parent
            color: Appearance.colors.colSecondaryHover
            text: DateTime.date.substring(5,7)
            font {
                family: Appearance.font.family.expressive
                pixelSize: 20
                weight: 1000
            }
        }
    }

    // Date bubble style left side
    Rectangle{
        z: 5
        implicitWidth: Config.options.background.clock.cookie.dateStyle === "bubble" ? dateSquareSize : 0
        implicitHeight: Config.options.background.clock.cookie.dateStyle === "bubble" ? dateSquareSize : 0
        color: Appearance.colors.colPrimaryContainerHover
        radius: Appearance.rounding.large
        anchors{
            left: cookie.left
            bottom: cookie.bottom
            bottomMargin: 5
        }
        Behavior on implicitWidth{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText{
            anchors.centerIn: parent
            text: DateTime.date.substring(5,7)
            color: Appearance.colors.colPrimary
            opacity: Config.options.background.clock.cookie.dateStyle === "bubble" ? 1.0 : 0
            font {
                family: Appearance.font.family.reading
                pixelSize: 30
                weight: 1000
            }
            Behavior on opacity{
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    // Date bubble style right side
    Rectangle{
        z: 5
        implicitWidth: Config.options.background.clock.cookie.dateStyle === "bubble" ? dateSquareSize : 0
        implicitHeight: Config.options.background.clock.cookie.dateStyle === "bubble" ? dateSquareSize : 0
        color: Appearance.colors.colTertiaryContainer
        radius: Appearance.rounding.verylarge
        anchors{
            right: cookie.right
            top: cookie.top
            topMargin: 5
        }
        Behavior on implicitWidth{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        StyledText{
            anchors.centerIn: parent
            text: DateTime.date.substring(8,10)
            color: Appearance.colors.colTertiary
            opacity: Config.options.background.clock.cookie.dateStyle === "bubble" ? 1.0 : 0
            font {
                family: Appearance.font.family.reading
                pixelSize: 30
                weight: 1000
            }
            Behavior on opacity{
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
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
