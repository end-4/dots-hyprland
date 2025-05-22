import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

RippleButton {
    id: button
    property string buttonIcon
    property bool activated: false
    toggled: activated

    implicitHeight: 30
    implicitWidth: 30

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
