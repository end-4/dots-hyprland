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

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: Network.networkName.length > 0 && Network.networkName != "lo"
    halfToggled: Network.wifiEnabled
    buttonIcon: Network.materialSymbol
    titleText: Network.wifiEnabled ? "Wifi" : Network.ethernet ? "Ethernet" : "Network"
    descText: toggled ? Network.networkName : halfToggled ? Network.wifiScanning ? "Scanning" :  Network.wifiConnecting ? "Connecting" : "On" : "Off"
    onClicked: {
        if (GlobalStates.quickTogglesEditMode) return;
        Network.toggleWifi()
    }
    altAction: () => {
        if (GlobalStates.quickTogglesEditMode) return;
        Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`])
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        text: Translation.tr("%1 | Right-click to configure").arg(Network.networkName)
    }
}

