import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

AndroidQuickToggleButton {
    id: root
    toggled: GlobalStates.oskOpen
    buttonIcon: toggled ? "keyboard_hide" : "keyboard"
    titleText: Translation.tr("Keyboard")
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        GlobalStates.sidebarRightOpen = false;
        onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
    }
    StyledToolTip {
        text: titleText
    }
}