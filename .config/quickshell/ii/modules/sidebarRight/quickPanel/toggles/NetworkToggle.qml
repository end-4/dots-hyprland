import qs
import qs.services
import "../"
import QtQuick

QuickToggle {
    toggled: Network.networkName.length > 0 && Network.networkName != "lo"
    buttonIcon: Network.materialSymbol
    downAction: Network.toggleWifi
    toggleText: Network.wifiEnabled ? "Wifi" : Network.ethernet ? "Ethernet" : "Network"
    halfToggled: Network.wifiEnabled
    stateText: toggled ? Network.networkName : (halfToggled ? (Network.connecting ? "Connecting" : Network.scanning ? "Scanning" : "On") : "")
}
