pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property real numberSize: 80
    property real margins: 10
    property color color: Appearance.colors.colOnSecondaryContainer

    property real hourLineSize: 4
    property real minuteLineSize: 2
    property real hourLineLength: 18
    property real minuteLineLength: 7

    property int hours: 12
    property int minutes: 60

    // Full dial style hour lines
    Repeater {
        model: root.hours

        Item {
            required property int index
            rotation: 360 / root.hours * index
            anchors.fill: parent

            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.margins
                }
                implicitWidth: root.hourLineLength
                implicitHeight: root.hourLineSize
                radius: implicitWidth / 2
                color: root.color
            }
        }
    }

    // Minute lines
    Repeater {
        model: root.minutes

        Item {
            required property int index
            rotation: 360 / root.minutes * index 
            anchors.fill: parent

            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: root.margins
                }
                implicitWidth: root.minuteLineLength
                implicitHeight: root.minuteLineSize
                radius: implicitWidth / 2
                color: root.color
            }
        }
    }
}
