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

    // Hour/minutes numbers/dots/lines
    MinuteMarks {
        anchors.fill: parent
    }
    HourMarks {
        anchors.fill: parent
    }

    // Number column in the middle
    TimeColumn {
        anchors.centerIn: parent
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

    DateIndicator {
        anchors.fill: parent
        colOnBackground: root.colOnBackground
        style: Config.options.background.clock.cookie.dateStyle
    }

}
