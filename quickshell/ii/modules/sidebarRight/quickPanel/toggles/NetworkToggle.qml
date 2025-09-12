
import qs
import qs.services
import "../"
import "../services/"

QuickToggle  {
    toggled: Network.networkName.length > 0 && Network.networkName != "lo"
    buttonIcon: Network.materialSymbol
    downAction: () => Network.toggleWifi()
    toggleText: Network.wifi ? "Wifi" : Network.ethernet ? "Ethernet" : "Network"
    stateText: Network.networkName.length > 0 && Network.networkName != "lo" ? Network.networkName : toggled ? "On" : "Off"
    halfToggled : Network.wifiEnabled

    altAction: () => {
        Network.enableWifi();
        Network.rescanWifi();
        GlobalStates.showWifiDialog = true;
        DialogContext.showWifiDialog = true;
    }

}
