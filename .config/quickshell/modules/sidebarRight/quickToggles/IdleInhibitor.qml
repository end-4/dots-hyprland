import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell.Io
import Quickshell

QuickToggleButton {
    toggled: idleInhibitor.running
    buttonIcon: "coffee"
    onClicked: {
        idleInhibitor.running = !idleInhibitor.running
    }
    Process {
        id: idleInhibitor
        command: ["bash", "-c", "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/wayland-idle-inhibitor.py"]
    }
    StyledToolTip {
        content: "Keep system awake"
    }
}
