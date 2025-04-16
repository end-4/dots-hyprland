import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "../"
import Quickshell.Io
import Quickshell
import QtQuick

QuickToggleButton {
    toggled: Network.networkName.length > 0 && Network.networkName != "lo"
    buttonIcon: toggled ? (
        Network.networkStrength > 80 ? "signal_wifi_4_bar" :
        Network.networkStrength > 60 ? "network_wifi_3_bar" :
        Network.networkStrength > 40 ? "network_wifi_2_bar" :
        Network.networkStrength > 20 ? "network_wifi_1_bar" :
        "signal_wifi_0_bar"
    ) : "signal_wifi_off"
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: {
            if (mouse.button === Qt.LeftButton) {
                toggleNetwork.running = true
            }
            if (mouse.button === Qt.RightButton) {
                configureNetwork.running = true
            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
    }
    Process {
        id: configureNetwork
        command: ["bash", "-c", `${ConfigOptions.apps.network} & qs ipc call sidebarRight close`]
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
        content: `${Network.networkName} | Right-click to configure`
    }
}
