pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

import qs.modules.background.cookieClock.dateIndicator
import qs.modules.background.cookieClock.minuteMarks

Item {
    id: root

    readonly property string clockStyle: Config.options.background.clock.style

    property real implicitSize: 230

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colSecondary, Appearance.colors.colSecondaryContainer, 0.15)
    property color colBackgroundInfo: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.55)
    property color colHourHand: Appearance.colors.colPrimary
    property color colMinuteHand: Appearance.colors.colSecondary
    property color colSecondHand: Appearance.colors.colTertiary

    readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: DateTime.clock.minutes
    readonly property int clockSecond: DateTime.clock.seconds

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    function applyStyle(sides, dialStyle, hourHandStyle, minuteHandStyle, secondHandStyle, dateStyle) {
        Config.options.background.clock.cookie.sides = sides
        Config.options.background.clock.cookie.dialNumberStyle = dialStyle
        Config.options.background.clock.cookie.hourHandStyle = hourHandStyle
        Config.options.background.clock.cookie.minuteHandStyle = minuteHandStyle
        Config.options.background.clock.cookie.secondHandStyle = secondHandStyle
        Config.options.background.clock.cookie.dateStyle = dateStyle
    }

    function setClockPreset(category) {
        if (!Config.options.background.clock.cookie.aiStyling) return;
        if (category === "") return;
        print("[Cookie clock] Setting clock preset for category: " + category)
        // "abstract", "anime", "city", "minimalist", "landscape", "plants", "person", "space"
        if (category == "abstract") {
            applyStyle(10, "dots", "fill", "medium", "dot", "bubble")
        } else if (category == "anime") {
            applyStyle(12, "dots", "fill", "bold", "dot", "bubble")
        } else if (category == "city" || category == "space") {
            applyStyle(23, "full", "hollow", "thin", "classic", "bubble")
        } else if (category == "minimalist") {
            applyStyle(6, "none", "fill", "bold", "dot", "hide")
        } else if (category == "landscape") {
            applyStyle(14, "full", "hollow", "medium", "classic", "bubble")
        } else if (category == "plants") {
            applyStyle(9, "dots", "fill", "bold", "dot", "border")
        } else if (category == "person") {
            applyStyle(14, "full", "classic", "classic", "classic", "rect")
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            categoryFileView.path = Directories.generatedWallpaperCategoryPath
        }
    }

    FileView {
        id: categoryFileView
        path: ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.setClockPreset(categoryFileView.text().trim())
        }
    }

    DropShadow {
        source: cookie
        anchors.fill: source
        horizontalOffset: 0
        verticalOffset: 1
        radius: 8
        samples: radius * 2 + 1
        color: root.colShadow
        transparentBorder: true
    }

    MaterialCookie {
        id: cookie
        z: 0
        implicitSize: root.implicitSize
        amplitude: implicitSize / 70
        sides: Config.options.background.clock.cookie.sides
        color: root.colBackground
        constantlyRotate: Config.options.background.clock.cookie.constantlyRotate
    
        // Hour/minutes numbers/dots/lines
        MinuteMarks {
            anchors.fill: parent
            color: root.colOnBackground
        }

        // Stupid extra hour marks in the middle
        FadeLoader {
            id: hourMarksLoader
            anchors.centerIn: parent
            shown: Config.options.background.clock.cookie.hourMarks
            sourceComponent: HourMarks {
                implicitSize: 135 * (1.75 - 0.75 * hourMarksLoader.opacity)
                color: root.colOnBackground
                colOnBackground: ColorUtils.mix(root.colBackgroundInfo, root.colOnBackground, 0.5)
            }
        }

        // Number column in the middle
        FadeLoader {
            id: timeColumnLoader
            anchors.centerIn: parent
            shown: Config.options.background.clock.cookie.timeIndicators
            scale: 1.4 - 0.4 * timeColumnLoader.shown
            Behavior on scale {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            sourceComponent: TimeColumn {
                color: root.colBackgroundInfo
            }
        }

        // Hour hand
        FadeLoader {
            anchors.fill: parent
            z: 1
            shown: Config.options.background.clock.cookie.hourHandStyle !== "hide"
            sourceComponent: HourHand {
                clockHour: root.clockHour
                clockMinute: root.clockMinute
                style: Config.options.background.clock.cookie.hourHandStyle
                color: root.colHourHand
            }
        }

        // Minute hand
        FadeLoader {
            anchors.fill: parent
            z: 2
            shown: Config.options.background.clock.cookie.minuteHandStyle !== "hide"
            sourceComponent: MinuteHand {
                anchors.fill: parent
                clockMinute: root.clockMinute
                style: Config.options.background.clock.cookie.minuteHandStyle
                color: root.colMinuteHand
            }
        }

        // Second hand
        FadeLoader {
            id: secondHandLoader
            z: (Config.options.background.clock.cookie.secondHandStyle === "line") ? 2 : 3
            shown: Config.options.time.secondPrecision && Config.options.background.clock.cookie.secondHandStyle !== "hide"
            anchors.fill: parent
            sourceComponent: SecondHand {
                id: secondHand
                clockSecond: root.clockSecond
                style: Config.options.background.clock.cookie.secondHandStyle
                color: root.colSecondHand
            }
        }

        // Center dot
        FadeLoader {
            z: 4
            anchors.centerIn: parent
            shown: Config.options.background.clock.cookie.minuteHandStyle !== "bold"
            sourceComponent: Rectangle {
                color: Config.options.background.clock.cookie.minuteHandStyle === "medium" ? root.colBackground : root.colMinuteHand
                implicitWidth: 6
                implicitHeight: implicitWidth
                radius: width / 2
            }
        }

        // Date
        FadeLoader {
            anchors.fill: parent
            shown: Config.options.background.clock.cookie.dateStyle !== "hide"

            sourceComponent: DateIndicator {
                color: root.colBackgroundInfo
                style: Config.options.background.clock.cookie.dateStyle
            }
        }
    }
}
