import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
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
        color: button.activated ? Appearance.m3colors.m3primary :
            button.down ? Appearance.colors.colSurfaceContainerHighestActive : 
            button.hovered ? Appearance.colors.colSurfaceContainerHighestHover :
            Appearance.m3colors.m3surfaceContainerHighest
    }

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.large
        color: button.activated ? Appearance.m3colors.m3onPrimary :
            Appearance.m3colors.m3onSurface
        text: buttonIcon
    }
}
