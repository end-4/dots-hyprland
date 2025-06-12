import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    toggled: false
    buttonIcon: "coffee"
    onClicked: {
        if (toggled) {
            root.toggled = false
            Hyprland.dispatch("exec pkill wayland-idle") // pkill doesn't accept too long names
        } else {
            root.toggled = true
            Hyprland.dispatch('exec ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/wayland-idle-inhibitor.py')
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", "pidof wayland-idle-inhibitor.py"]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode === 0
        }
    }
    StyledToolTip {
        content: qsTr("Keep system awake")
    }
}
