pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property string style: Config.options.background.widgets.clock.cookie.dateStyle
    property color color: Appearance.colors.colOnSecondaryContainer
    property real angleStep: 12 * Math.PI / 180
    property string dateText: Qt.locale().toString(DateTime.clock.date, "ddd dd")
    
    readonly property int clockSecond: DateTime.clock.seconds
    readonly property string dialStyle: Config.options.background.widgets.clock.cookie.dialNumberStyle
    readonly property bool timeIndicators: Config.options.background.widgets.clock.cookie.timeIndicators

    property real radius: style === "border" ? 90 : 0
    Behavior on radius {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    rotation: {
        if (!Config.options.time.secondPrecision) return 0
        else return (360 / 60 * clockSecond) + 180 - (angleStep / Math.PI * 180 * dateText.length) / 2
    }

    Repeater {
        model: root.dateText.length 

        delegate: Text {
            required property int index
            property real angle: index * root.angleStep - Math.PI / 2
            x: root.width / 2 + root.radius * Math.cos(angle) - width / 2
            y: root.height / 2 + root.radius * Math.sin(angle) - height / 2
            rotation: angle * 180 / Math.PI + 90

            color: root.color
            font {
                family: Appearance.font.family.title
                pixelSize: 30
                variableAxes: Appearance.font.variableAxes.title
            }

            text: root.dateText.charAt(index)
        }
    }
}
