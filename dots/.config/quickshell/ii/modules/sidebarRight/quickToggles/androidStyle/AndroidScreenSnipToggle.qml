import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

AndroidQuickToggleButton {
    id: root
    toggled: false
    buttonIcon: "screenshot_region"
    titleText: Translation.tr("Screenshot")
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        GlobalStates.sidebarRightOpen = false;
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("screenshot.qml")])
    }
    StyledToolTip {
        text: titleText
    }
}