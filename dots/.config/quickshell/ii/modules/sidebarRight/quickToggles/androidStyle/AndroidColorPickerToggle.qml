import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Color Picker")
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
}
