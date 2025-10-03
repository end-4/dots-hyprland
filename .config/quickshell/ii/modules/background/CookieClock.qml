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

    property real implicitSize: 230
    property real hourHandLength: 72
    property real hourHandWidth: 16
    property real minuteHandLength: 95
    property real minuteHandWidth: 8
    property real centerDotSize: 10
    property real hourDotSize: minuteHandWidth

    property color colShadow: Appearance.colors.colShadow
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colOnBackground: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.5)
    property color colHourHand: Appearance.colors.colPrimary
    property color colMinuteHand: Appearance.colors.colSecondary
    property color colOnHourHand: Appearance.colors.colOnPrimary

    readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: parseInt(clockNumbers[1])
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
        sides: 12
        color: root.colBackground

        // 12 dots around the cookie
        Repeater {
            model: 12
            Item {
                required property int index
                rotation: 360 / 12 * index
                anchors.fill: parent
                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    implicitWidth: root.hourDotSize
                    implicitHeight: implicitWidth
                    radius: implicitWidth / 2
                    color: root.colOnBackground
                    opacity: 0.5
                }
            }
        }
    }

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

                anchors.horizontalCenter: parent?.horizontalCenter
                font {
                    pixelSize: modelData.match(/am|pm/i) ? 26 : 68
                    family: Appearance.font.family.expressive
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
        z: 2
        rotation: -90 + (360 / 12) * (root.clockHour + root.clockMinute / 60)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width / 2 - hourHandWidth / 2
            width: hourHandLength
            height: hourHandWidth
            radius: hourHandWidth / 2
            color: root.colHourHand
        }
    }

    // Minute hand
    Item {
        anchors.fill: parent
        z: 3
        rotation: -90 + (360 / 60) * root.clockMinute
        Rectangle {
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
        z: 4
        color: root.colOnHourHand
        anchors.centerIn: parent
        implicitWidth: centerDotSize
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
    }
}
