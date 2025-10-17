import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

AndroidQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: false
    buttonIcon: "screenshot_region"
    titleText: "Screenshot"
    descText: "Click me"
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        GlobalStates.sidebarRightOpen = false;
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("screenshot.qml")])
    }
    StyledToolTip {
        text: "Screenshot"
    }
}