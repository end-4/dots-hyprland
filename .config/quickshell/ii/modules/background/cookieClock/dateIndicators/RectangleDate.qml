
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Rectangle {
    readonly property string dialStyle: Config.options.background.clock.cookie.dialNumberStyle
    property real animIndex: 0
    opacity: animIndex 

    width: 45
    height: 30

    x: dialStyle === "numbers" ? 155 : 150
    y: dialStyle === "numbers" ? 155 : 100 

    Behavior on x {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    StyledText {
        opacity: root.style === "rect" ? 1.0 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: DateTime.date.substring(5, 7)
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: 1000
        }
    }
}