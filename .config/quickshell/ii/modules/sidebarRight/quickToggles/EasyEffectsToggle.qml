import qs.modules.common.widgets
import qs
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    toggled: false
    visible: false
    buttonIcon: "instant_mix"

    onClicked: {
        if (toggled) {
            root.toggled = false
            Quickshell.execDetached(["pkill", "easyeffects"])
        } else {
            root.toggled = true
            Quickshell.execDetached(["easyeffects", "--gapplication-service"])
        }
    }

    altAction: () => {
        Quickshell.execDetached(["easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }

    Process {
        id: fetchAvailability
        running: true
        command: ["bash", "-c", "command -v easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.visible = exitCode === 0
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["pidof", "easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode === 0
        }
    }

    StyledToolTip {
        content: Translation.tr("EasyEffects | Right-click to configure")
    }
}
