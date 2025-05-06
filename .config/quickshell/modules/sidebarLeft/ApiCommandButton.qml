import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Button {
    id: button
    property string buttonText

    implicitHeight: 30
    leftPadding: 10
    rightPadding: 10

    PointingHandInteraction {}

    background: Rectangle {
        radius: Appearance.rounding.small
        color: (button.down ? Appearance.colors.colSurfaceContainerHighestActive : 
            button.hovered ? Appearance.colors.colSurfaceContainerHighestHover :
            Appearance.m3colors.m3surfaceContainerHighest)
    }

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: Appearance.m3colors.m3onSurface
    }
}