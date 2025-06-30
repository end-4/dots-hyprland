import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "../"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: Network.networkName.length > 0 && Network.networkName != "lo"
    buttonIcon: Network.materialSymbol
    onClicked: {
        toggleNetwork.running = true
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`])
        Hyprland.dispatch("global quickshell:sidebarRightClose")
    }
    Process {
        id: toggleNetwork
        command: ["bash", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]
        onRunningChanged: {
            if(!running) {
                Network.update()
            }
        }
    }
    StyledToolTip {
        content: StringUtils.format(qsTr("{0} | Right-click to configure"), Network.networkName)
    }
}
