import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import QtQuick
import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: false
    buttonIcon: "colorize"
    titleText: "Color Picker"
    descText: "Click me"
    onClicked: {
        if (Config.options.quickToggles.android.inEditMode) return;
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start() // Using a timer to wait sidebarRight close
        
    }
    Timer {
        id: delayedActionTimer
        interval: 20 * (1000 / 60) 
        repeat: false 
        onTriggered: {
            Quickshell.execDetached(["hyprpicker", "-a"])
        }
    }
    StyledToolTip {
        text: "Color Picker"
    }
}