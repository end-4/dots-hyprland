import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon

    implicitWidth: 40
    implicitHeight: 40

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: toggled ? 
            (button.down ? Appearance.colors.colPrimaryActive : button.hovered ? Appearance.colors.colPrimaryHover : Appearance.m3colors.m3primary) :
            (button.down ? Appearance.colors.colLayer1Active : button.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1))

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)

        }
        
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.larger
            fill: toggled ? 1 : 0
            text: buttonIcon
            color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

    }

}
