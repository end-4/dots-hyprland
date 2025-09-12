import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick
import Quickshell.Io
import Quickshell

import qs
import qs.services
import "../"

QuickToggle  {
    toggled: Appearance.m3colors.darkmode
    buttonIcon: "radio_button_partial"
    toggleText: "Dark Mode"
    downAction: () => {
                Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${toggled ? "light" : "dark"} --noswitch`]);
            }


}
