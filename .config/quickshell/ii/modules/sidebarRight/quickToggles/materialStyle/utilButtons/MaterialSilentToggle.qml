import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: Notifications.silent
    buttonIcon: toggled ? "notifications_paused" : "notifications_active"
    titleText: "Notifications"
    altText: toggled ? "Silent" : "On" 
    onClicked: {
        if (GlobalStates.quickTogglesEditMode) return;
        Notifications.silent = !Notifications.silent;
    }
    StyledToolTip {
        text: "Do Not Disturb"
    }
}