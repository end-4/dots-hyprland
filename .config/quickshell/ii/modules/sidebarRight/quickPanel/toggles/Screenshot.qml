import QtQuick
import qs
import Quickshell
import "../"

QuickToggle {
    id: root
    toggled: false
    buttonIcon: "screenshot_monitor"
    downAction: () => {
        root.toggled = true;
        delayTimer.start();
    }
    toggleText: "Screenshot"
    stateText: ""

    Timer {
        id: delayTimer
        interval: 350 // delay for click animation
        repeat: false
        onTriggered: {
            root.toggled = false;
            GlobalStates.sidebarRightOpen = false;
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("screenshot.qml")]);
        }
    }
}
