import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: 60
    clickedHeight: 40
    toggled: false
    buttonRadius: Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small

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
