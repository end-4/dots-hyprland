import qs
import qs.modules.common
import Quickshell

import "../"

QuickToggle {
    toggled: Appearance.m3colors.darkmode
    buttonIcon: "radio_button_partial"
    toggleText: "Dark Mode"
    downAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${toggled ? "light" : "dark"} --noswitch`]);
        toggled = !toggled;
    }
}
