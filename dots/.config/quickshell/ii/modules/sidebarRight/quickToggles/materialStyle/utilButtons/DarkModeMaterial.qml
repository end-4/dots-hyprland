import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Hyprland
import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: Appearance.m3colors.darkmode
    buttonIcon: Appearance.m3colors.darkmode ? "contrast" : "light_mode"
    titleText: "Dark Mode"
    descText: toggled ? "On" : "Off"
    onClicked: event => {
        if (GlobalStates.quickTogglesEditMode) return;
        if (Appearance.m3colors.darkmode) {
            Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`);
        } else {
            Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`);
        }
    }
    StyledToolTip {
        text: "Dark Mode"
    }
}