import "root:/modules/common"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RippleButton {
    id: button

    property string buttonText
    implicitHeight: 30
    implicitWidth: buttonTextWidget.implicitWidth + 15 * 2
    buttonRadius: Appearance.rounding.full

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.small
        color: button.enabled ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
