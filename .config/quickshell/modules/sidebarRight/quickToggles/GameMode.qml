import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell.Io
import Quickshell

QuickToggleButton {
    property bool enabled: false
    buttonIcon: "gamepad"
    toggled: enabled
    onClicked: {
        enabled = !enabled
        if (enabled) {
            gameModeOn.running = true
        } else {
            gameModeOff.running = true
        }
    }
    Process {
        id: gameModeOn
        command: ['bash', '-c', `hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`]
    }
    Process {
        id: gameModeOff
        command: ['bash', '-c', `hyprctl reload`]
    }
    StyledToolTip {
        content: qsTr("Game mode")
    }
}