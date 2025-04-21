import "root:/modules/common"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Button {
    id: button
    property string buttonText
    property string urgency

    implicitHeight: 30
    leftPadding: 10
    rightPadding: 10

    // PointingHandInteraction {}

    background: Rectangle {
        radius: Appearance.rounding.small
        color: (urgency == NotificationUrgency.Critical) ? 
        (button.down ? Appearance.colors.colSecondaryContainerActive : 
            button.hovered ? Appearance.colors.colSecondaryContainerHover : 
            Appearance.m3colors.m3secondaryContainer) : 
        (button.down ? Appearance.colors.colSurfaceContainerHighestActive : 
            button.hovered ? Appearance.colors.colSurfaceContainerHighestHover :
            Appearance.m3colors.m3surfaceContainerHighest)

    }

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }
}