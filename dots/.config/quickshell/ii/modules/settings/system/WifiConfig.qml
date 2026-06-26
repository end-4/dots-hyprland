import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import "../../ii/sidebarRight/wifiNetworks" as WifiNetworks

ContentPage {
    forceWidth: true

    Component.onCompleted: {
        Network.update();
        Network.rescanWifi();
    }

    ContentSection {
        icon: Network.materialSymbol
        title: Translation.tr("Networks")

        ConfigSwitch {
            buttonIcon: Network.wifiEnabled ? "wifi" : "signal_wifi_off"
            text: Network.wifiEnabled ? Translation.tr("Wi-Fi enabled") : Translation.tr("Wi-Fi disabled")
            checked: Network.wifiEnabled
            onCheckedChanged: {
                Network.enableWifi(checked);
                if (checked)
                    Network.rescanWifi();
            }
        }

        ConfigRow {
            DialogButton {
                buttonText: Network.wifiScanning ? Translation.tr("Scanning") : Translation.tr("Scan")
                enabled: Network.wifiEnabled && !Network.wifiScanning
                onClicked: Network.rescanWifi()
            }

            DialogButton {
                visible: Network.active !== null
                buttonText: Translation.tr("Disconnect")
                onClicked: Network.disconnectWifiNetwork()
            }

            StyledText {
                Layout.fillWidth: true
                text: Network.wifiStatus === "connected"
                    ? Translation.tr("Connected to %1").arg(Network.networkName || Network.active?.ssid || Translation.tr("Unknown"))
                    : Network.wifiStatus === "disabled"
                        ? Translation.tr("Wireless radio is off")
                        : Translation.tr("Not connected")
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }
    }

    ContentSection {
        icon: "travel_explore"
        title: Translation.tr("Available networks")

        StyledText {
            Layout.fillWidth: true
            visible: !Network.wifiEnabled
            text: Translation.tr("Turn on Wi-Fi to scan for networks.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: Network.wifiEnabled && !Network.wifiScanning && Network.friendlyWifiNetworks.length === 0
            text: Translation.tr("No networks found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: Network.wifiScanning
            text: Translation.tr("Scanning for networks...")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: ScriptModel {
                values: Network.friendlyWifiNetworks
            }

            WifiNetworks.WifiNetworkItem {
                required property WifiAccessPoint modelData
                Layout.fillWidth: true
                wifiNetwork: modelData
            }
        }
    }
}
