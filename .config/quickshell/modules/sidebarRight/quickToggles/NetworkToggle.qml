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
        onClicked: (mouse) =>{
            if (mouse.button === Qt.LeftButton) {
                toggleNetwork.running = true
            }
            if (mouse.button === Qt.RightButton) {
                Hyprland.dispatch(`exec ${ConfigOptions.apps.network}`)
                Hyprland.dispatch("global quickshell:sidebarRightClose")
            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor 
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
