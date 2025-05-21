import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Button {
    id: button

    property string buttonText
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + 14 * 2

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        color: (button.down && button.enabled) ? ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.84) : 
            ((button.hovered && button.enabled) ? ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.92) : 
            ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 1))

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: buttonText
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: Appearance.font.pixelSize.small
        color: button.enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
