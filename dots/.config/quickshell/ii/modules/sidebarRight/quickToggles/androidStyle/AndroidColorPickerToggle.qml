import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Color picker")
    statusText: ""
    toggled: false
    buttonIcon: "colorize"

    onClicked: {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start()
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false 
        onTriggered: {
            Quickshell.execDetached(["hyprpicker", "-a"])
        }
    }

    StyledToolTip {
        text: Translation.tr("Color picker")
    }
}
