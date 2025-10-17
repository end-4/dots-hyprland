import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

AndroidQuickToggleButton {
    id: root
    toggled: Notifications.silent
    buttonIcon: toggled ? "notifications_paused" : "notifications_active"
    titleText: "Do Not Disturb"
    descText: toggled ? "Silent" : "Noisy" 
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        Notifications.silent = !Notifications.silent;
    }
    StyledToolTip {
        text: "Do Not Disturb"
    }
}