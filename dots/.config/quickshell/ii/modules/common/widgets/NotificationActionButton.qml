import qs.modules.common
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    buttonRadius: Appearance.rounding.small
    colBackground: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer4
    colBackgroundHover: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer4Hover
    colRipple: (urgency == NotificationUrgency.Critical) ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colLayer4Active

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }
}