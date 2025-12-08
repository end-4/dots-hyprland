import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("VPN")
    statusText: Network.vpnEnabled ? Translation.tr("enabled") : Translation.tr("disabled")
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(Network.vpnEnabled ? Translation.tr("enabled") : Translation.tr("disabled"))
    icon: "vpn_lock"
    
    toggled: Network.vpnEnabled
    mainAction: Network.toggleVpnConnection(Config.options.vpn.defaultVpn, Network.vpnEnabled)
    hasMenu: true
}
