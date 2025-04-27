import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    property bool enabled: false
    buttonIcon: "gamepad"
    toggled: enabled

    onClicked: {
        enabled = !enabled
        if (enabled) {
            // gameModeOn.running = true
            Hyprland.dispatch(`exec hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`)
        } else {
            Hyprland.dispatch("exec hyprctl reload")
        }
    }
    
    StyledToolTip {
        content: qsTr("Game mode")
    }
}