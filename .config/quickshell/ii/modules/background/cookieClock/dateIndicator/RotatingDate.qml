pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property string style: Config.options.background.clock.cookie.dateStyle
    readonly property string dialStyle: Config.options.background.clock.cookie.dialNumberStyle
    readonly property bool timeIndicators: Config.options.background.clock.cookie.timeIndicators

    property real radius: style === "rotating" ? 90 : 0
    Behavior on radius {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    property string dateText: Qt.locale().toString(DateTime.clock.date, "ddd dd")
    property real angleStep: Math.PI / 2.35 / dateText.length

    property color dayColor: Appearance.colors.colSecondary
    property color monthColor: Appearance.colors.colSecondaryHover

    opacity: style === "rotating" ? 1.0 : 0.0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    rotation: {
        if (!Config.options.time.secondPrecision) return 0
        else return secondHandLoader.item.rotation + 45 // +45 to center the text
    }

    Repeater {
        model: root.dateText.length 

        delegate: Text {
            required property int index
            property real angle: index * root.angleStep - Math.PI / 2

            x: root.width / 2 + root.radius * Math.cos(angle) - width / 2
            y: root.height / 2 + root.radius * Math.sin(angle) - height / 2

            text: root.dateText.charAt(index)

            font.family: Appearance.font.family.title
            font.pixelSize: 30
            font.weight: Font.DemiBold 

            color: index < 3 ? root.dayColor : root.monthColor

            rotation: angle * 180 / Math.PI + 90

        }
    }
}
