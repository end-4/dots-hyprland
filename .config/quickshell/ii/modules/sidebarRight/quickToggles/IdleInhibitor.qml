import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import "root:/"
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
            Quickshell.execDetached(["pkill", "wayland-idle"]) // pkill doesn't accept too long names
        } else {
            root.toggled = true
            Quickshell.execDetached([`${Directories.scriptPath}/wayland-idle-inhibitor.py`])
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
        content: Translation.tr("Keep system awake")
    }
}
