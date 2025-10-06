pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Column {
    id: timeIndicators
    z: 1
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
