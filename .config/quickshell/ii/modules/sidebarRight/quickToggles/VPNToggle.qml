import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "../"
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: VPN.connected
    buttonIcon: VPN.materialSymbol
    visible: VPN.available
    onClicked: {
    	if (VPN.connected) {
        	disconnectVPN.running = true
        }
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.network}`])
        GlobalStates.sidebarRightOpen = false
    }
    Process {
        id: disconnectVPN
        command: ["bash", "-c", "nmcli connection down $(nmcli -g UUID,TYPE connection show --active | awk -F: '/vpn|wireguard/{print $1}')"]
    }
    StyledToolTip {
        content: Translation.tr("%1 | Right-click to configure").arg(VPN.vpnName)
    }
}
