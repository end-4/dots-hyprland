import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

AndroidQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: GlobalStates.oskOpen
    buttonIcon: toggled ? "keyboard_hide" : "keyboard"
    titleText: "Keyboard"
    descText: toggled ? "On" : "Off"
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        GlobalStates.sidebarRightOpen = false;
        onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
    }
    StyledToolTip {
        text: "Toggle Keyboard"
    }
}