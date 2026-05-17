import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: Network.vpnEnabled
    buttonIcon: "vpn_lock"
    onClicked: Network.toggleVpnConnection(Config.options.vpn.defaultVpn, Network.vpnEnabled)
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`])
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        text: Translation.tr("%1 | Right-click to configure").arg(Network.vpnEnabled ? Translation.tr("Enabled") : Translation.tr("Disabled"))
    }
}
