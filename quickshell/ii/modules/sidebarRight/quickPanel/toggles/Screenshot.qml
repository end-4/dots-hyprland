

import qs
import qs.services
import Quickshell
import Quickshell.Io
import "../"

QuickToggle  {
    toggled: false
    buttonIcon: "screenshot_monitor"
    downAction: () => Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("screenshot.qml")])
    toggleText: "Screenshot"
    stateText: ""
    altAction: downAction


}
