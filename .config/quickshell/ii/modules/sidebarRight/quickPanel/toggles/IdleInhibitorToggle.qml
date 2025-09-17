import qs
import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Io
import "../"

QuickToggle {
    id: root
    toggled: false
    halfToggled: false
    buttonIcon: "coffee"
    toggleText: "Stay awake"
    stateText: toggled ? "Active" : "Inactive"
    downAction: () => {
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
        command: ["pidof", "wayland-idle-inhibitor.py"]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode === 0
        }
    }
}
