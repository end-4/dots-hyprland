import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Button {
    id: button
    property string buttonIcon
    property bool activated: false

    implicitHeight: 30
    implicitWidth: 30

    PointingHandInteraction {}

    background: Rectangle {
        radius: Appearance.rounding.small
        color: !button.enabled ? ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 1) : 
            button.activated ? (button.down ? Appearance.colors.colPrimaryActive : 
            button.hovered ? Appearance.colors.colPrimaryHover :
            Appearance.m3colors.m3primary) :
            (button.down ? Appearance.colors.colSurfaceContainerHighestActive : 
            button.hovered ? Appearance.colors.colSurfaceContainerHighestHover :
            ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 1))

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.large
        text: buttonIcon
        color: button.activated ? Appearance.m3colors.m3onPrimary :
            button.enabled ? Appearance.m3colors.m3onSurface :
            Appearance.colors.colOnLayer1Inactive

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
