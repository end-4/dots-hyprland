import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import Quickshell.Hyprland
import "../"

AndroidQuickToggleButton {
    id: root
    toggled: Appearance.m3colors.darkmode
    buttonIcon: Appearance.m3colors.darkmode ? "contrast" : "light_mode"
    titleText: Translation.tr("Dark Mode")
    onClicked: event => {
        if (Config.options.quickToggles.android.inEditMode) return;
        if (Appearance.m3colors.darkmode) {
            Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`);
        } else {
            Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`);
        }
    }
    StyledToolTip {
        text: titleText
    }
}