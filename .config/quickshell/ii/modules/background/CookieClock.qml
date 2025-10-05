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
    readonly property bool showQuote: Config.options.background.showQuote && Config.options.background.quote.length > 0 && !GlobalStates.screenLocked


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
    

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.5)
    property color colMinuteHand: Appearance.colors.colPrimary
    property color colHourHand: Appearance.colors.colSecondaryActive
    property color colOnHourHand: Appearance.colors.colOnPrimary
    property color colTimeIndicators: Appearance.colors.colSecondaryContainerHover
    property color colSeconds: Appearance.colors.colTertiary
    readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: parseInt(clockNumbers[1])

    property int clockSecond: 0

    Loader{
        active: Config.option.background.clock.cookie.secondDot
        sourceComponent: Timer {
            interval: 1000 
            running: true;repeat: true
            onTriggered: {
                var now = new Date()
                clockSecond = now.getSeconds()
            }
        }
    }



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
    DropShadow {
        source: quoteBox 
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

        
    }

    // 12 dots around the cookie
    Repeater {
        model: 12
        Item {
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "dots" ? 1.0 : 0 // Not using visible to allow smooth transition
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            required property int index
            rotation: 360 / 12 * index 
            anchors.fill: parent
            Rectangle {
                anchors {
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
                opacity: Config.options.background.clock.cookie.centerGlow ? 1.0 : 0 // Not using visible to allow smooth transition
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                required property int index
                rotation: 360 / 12 * index 
                anchors.fill: parent
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

        // Numbers
        Repeater {
            model: root.clockNumbers
            delegate: StyledText {
                required property string modelData

                opacity: Config.options.background.clock.cookie.timeIndicators ? 1.0 : 0 // Not using visible to allow smooth transition
                Behavior on opacity { 
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                anchors.horizontalCenter: parent?.horizontalCenter
                font {
                    // A better way to do this? probably yes, do i know : no
                    // (changing size based on am/pm selected or not)
                    property real numberSizeWithoutGlow: modelData.match(/am|pm/i) ? 26 : 68
                    property real numberSizeWithGlow: modelData.match(/am|pm/i) ? 10 : 40
                    pixelSize: !Config.options.background.clock.cookie.timeIndicators ? 100 : // for open/close animation
                                Config.options.background.clock.cookie.centerGlow ? numberSizeWithGlow : numberSizeWithoutGlow 
                    Behavior on pixelSize {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }
                    family: Appearance.font.family.main
                    weight: Font.Bold
                }
                color: root.colOnBackground
                text: modelData.padStart(2, "0")
            }
        }
    }

    // Hour hand
    Item {
        anchors.fill: parent
        z: Config.options.background.clock.cookie.hourHandStyle === "fill" ? 3 : 1
        rotation: -90 + (360 / 12) * (root.clockHour + root.clockMinute / 60)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - hourHandWidth / 2
            width: hourHandLength
            height: hourHandWidth
            radius: hourHandWidth / 2
            color: Config.options.background.clock.cookie.hourHandStyle === "stroke" ? "transparent" : root.colHourHand
            border.color: Config.options.background.clock.cookie.hourHandStyle === "stroke" ? root.colHourHand : "transparent"
            border.width: Config.options.background.clock.cookie.hourHandStyle === "stroke" ? 4 : 0
        }
    }

    // Minute hand
    Item {
        anchors.fill: parent
        z: Config.options.background.clock.cookie.minuteHandStyle === "thin" ? 1 : 3
        Behavior on rotation{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        rotation: -90 + (360 / 60) * root.clockMinute
        Rectangle {
            Behavior on height {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - minuteHandWidth / 2
            width: minuteHandLength
            height: minuteHandWidth
            radius: minuteHandWidth / 2
            color: root.colMinuteHand
        }
    }

    // Center dot
    Rectangle {
        opacity: Config.options.background.clock.cookie.minuteHandStyle !== "bold" ? 1.0 : 0 // Not using visible to allow smooth transition
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        z: 4
        color: Config.options.background.clock.cookie.minuteHandStyle === "medium" ? root.colBackground : root.colMinuteHand
        anchors.centerIn: parent
        implicitWidth: centerDotSize
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
    }

    // Center glow
    Rectangle {
        opacity: Config.options.background.clock.cookie.centerGlow ? 1.0 : 0 // Not using visible to allow smooth transition
        Behavior on opacity {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth { // Not using two animations because it looks weird
            ParallelAnimation {
                NumberAnimation { properties: "implicitWidth,implicitHeight"; duration: 100; easing.type: Easing.InOutQuad }
            }
        }
        z: 0
        color: root.colTimeIndicators
        anchors.centerIn: parent
        implicitWidth: Config.options.background.clock.cookie.centerGlow ? centerGlowSize : centerGlowSize * 1.75
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
    }


    // Second hand/dot
    Item {
        id: secondHand
        z: Config.options.background.clock.cookie.secondHandStyle === "line" ? 2 : 3
        opacity: Config.options.background.clock.cookie.secondHandStyle === "dot" || Config.options.background.clock.cookie.secondHandStyle === "line" ? 1.0 : 0 // Not using visible to allow smooth transition
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on rotation{
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        rotation: (360 / 60 * clockSecond) + 90 // +90 degrees to align with minute hand
        anchors.fill: parent
        Rectangle {
            
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
            implicitWidth: Config.options.background.clock.cookie.secondHandStyle === "dot" ? root.secondDotSize : root.secondsHandLength
            implicitHeight: Config.options.background.clock.cookie.secondHandStyle === "dot" ? implicitWidth : root.secondsHandWidth
            radius: Config.options.background.clock.cookie.secondHandStyle === "dot" ? implicitWidth / 2 : root.secondsHandWidth / 2
            color: colSeconds
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
            ctx.font = "700 30px gabarito";

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
        Behavior on implicitHeight{
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        opacity: 1.0
        anchors{
            verticalCenter: cookie.verticalCenter
            right: cookie.right
            rightMargin: 10
        }
        color: root.colOnBackground
        radius: Appearance.rounding.small // LOOK
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
    
    // Hour Indicator numbers (3-6-9-12)
    Repeater {
        model: 4
        Item {
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "numbers" ? 1.0 : 0 // Not using visible to allow smooth transition
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            required property int index
            rotation: 360 / 4 * index 
            anchors.fill: parent
            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "numbers" ? 32 : 96
                }
                Behavior on anchors.leftMargin{
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                implicitWidth: root.hourNumberSize
                implicitHeight: implicitWidth
                color: "transparent"
                StyledText{
                    
                    color: root.colOnBackground
                    anchors.centerIn: parent
                    text: index === 0 ? "9" : index === 1 ? "12" : index === 2 ? "3" : "6"
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
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            required property int index
            rotation: 360 / 12 * index 
            anchors.fill: parent
            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 10 : 50
                }
                Behavior on anchors.leftMargin{
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                implicitWidth: root.hourLineSize * 3.5
                implicitHeight: root.hourLineSize
                radius: implicitWidth / 2
                color: root.colOnBackground
                opacity: 1.0
            }
        }
    }
    // Full dial style minute lines
    Repeater {
        model: 60
        Item {
            opacity: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 1.0 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            required property int index
            rotation: 360 / 60 * index 
            anchors.fill: parent
            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Config.options.background.clock.cookie.dialNumberStyle === "full" ? 10 : 50
                }
                Behavior on anchors.leftMargin{
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                implicitWidth: root.minuteLineSize * 3.5
                implicitHeight: root.minuteLineSize
                radius: implicitWidth / 2
                color: root.colOnBackground
                opacity: 0.5
            }
        }
    }


    // Quote
    Rectangle{
        id: quoteBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 24
        
        implicitWidth: quoteText.width + quoteIcon.width + 16 // for spacing on both sides
        implicitHeight: showQuote ? quoteText.height + 8 : 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer
        
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        RowLayout{
            anchors.centerIn: parent
            spacing: 4
            
            MaterialSymbol{
                id: quoteIcon
                visible: showQuote > 0
                iconSize: Appearance.font.pixelSize.huge
                text: "comic_bubble"
            }
            StyledText{
                id: quoteText
                visible : showQuote > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Config.options.background.quote
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.large
                    weight: Font.Normal
                    italic: true
                }
            }
        }
    }
}
