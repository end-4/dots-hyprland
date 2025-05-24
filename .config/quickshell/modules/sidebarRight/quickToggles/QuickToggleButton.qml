import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

RippleButton {
    id: button
    rippleEnabled: false
    property string buttonIcon
    property int clickIndex: parent?.clickIndex ?? -1
    toggled: false
    buttonRadius: Appearance?.rounding?.full
    buttonRadiusPressed: Appearance?.rounding?.small

    Layout.fillWidth: (clickIndex - 1 <= parent.children.indexOf(button) && parent.children.indexOf(button) <= clickIndex + 1)
    implicitWidth: button.down ? 60 : 40
    implicitHeight: 40

    Behavior on implicitWidth {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    onDownChanged: {
        if (button.down) {
            if (button.parent.clickIndex !== undefined) {
                button.parent.clickIndex = parent.children.indexOf(button)
            }
        }
    }

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: Appearance.font.pixelSize.larger
        fill: toggled ? 1 : 0
        color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
