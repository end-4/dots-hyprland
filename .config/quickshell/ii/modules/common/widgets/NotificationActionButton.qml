import qs.modules.common
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency

    implicitHeight: 30
    leftPadding: 15
    rightPadding: 15
    buttonRadius: Appearance.rounding.small
    colBackground: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainer : Appearance.colors.colSurfaceContainerHighest
    colBackgroundHover: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSurfaceContainerHighestHover
    colRipple: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colSurfaceContainerHighestActive

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }
}