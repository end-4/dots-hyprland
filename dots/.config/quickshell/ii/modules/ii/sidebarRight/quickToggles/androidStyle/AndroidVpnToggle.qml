import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

AndroidQuickToggleButton {
    id: root
    
    name: Translation.tr("VPN")
    statusText: ""

    toggled: Network.vpnEnabled
    buttonIcon: "vpn_lock"
    onClicked: Network.updateVpnList()
    altAction: () => {
        root.openMenu();
        Network.updateVpnList();
    }
    StyledToolTip {
        text: Translation.tr("VPN %1 | Right-click to configure").arg(Network.vpnEnabled ? Translation.tr("enabled") : Translation.tr("disabled"))
    }
}