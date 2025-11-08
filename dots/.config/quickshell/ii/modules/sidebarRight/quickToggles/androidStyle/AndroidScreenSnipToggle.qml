import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Screen snip")
    statusText: ""
    toggled: false
    buttonIcon: "screenshot_region"

    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start()
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
        }
    }

    StyledToolTip {
        text: Translation.tr("Screen snip")
    }
}
