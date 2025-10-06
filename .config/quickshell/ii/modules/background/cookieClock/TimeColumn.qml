pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Column {
    id: root
    required property list<string> clockNumbers
    property bool isEnabled: Config.options.background.clock.cookie.timeIndicators
    property color color: Appearance.colors.colOnSecondaryContainer

    z: 1
    spacing: -16

    Repeater {
        model: root.clockNumbers

        delegate: StyledText {
            required property string modelData
            property bool hourMarksEnabled: Config.options.background.clock.cookie.hourMarks
            property bool isAmPm: !!modelData.match(/am|pm/i)
            property real numberSizeWithoutGlow: isAmPm ? 26 : 68
            property real numberSizeWithGlow: isAmPm ? 10 : 40
            property real numberSize: root.isEnabled ? (hourMarksEnabled ? numberSizeWithGlow : numberSizeWithoutGlow) : 100 // open/close animation

            anchors.horizontalCenter: root.horizontalCenter
            visible: opacity > 0
            color: root.color
            opacity: root.isEnabled ? 1.0 : 0

            Behavior on opacity { 
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            text: modelData.padStart(2, "0")

            font {
                family: Appearance.font.family.expressive
                weight: Font.Bold
                pixelSize: numberSize
                Behavior on pixelSize {
                    animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                }
            }
        }
    }
}
