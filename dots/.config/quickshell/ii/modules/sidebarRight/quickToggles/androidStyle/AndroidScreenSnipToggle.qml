import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Screen snip")
    statusText: ""
    toggled: false
    buttonIcon: "screenshot_region"

    onClicked: {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start()
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("screenshot.qml")])
        }
    }

    StyledToolTip {
        text: Translation.tr("Screen snip")
    }
}
