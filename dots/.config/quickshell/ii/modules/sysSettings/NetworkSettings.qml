import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Network & Wi-Fi settings — wraps the existing Network service.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "wifi"
        title: Translation.tr("Wi-Fi")

        ConfigSwitch {
            buttonIcon: "wifi"
            text: Translation.tr("Wi-Fi enabled")
            checked: Network.wifiEnabled
            onCheckedChanged: Network.enableWifi(checked)
        }

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: Network.active ? Translation.tr("Connected to: %1").arg(Network.networkName) : Translation.tr("Not connected")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
            RippleButton {
                implicitWidth: 36; implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                enabled: Network.wifiEnabled
                onClicked: Network.rescanWifi()
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 18 }
                StyledToolTip { text: Translation.tr("Rescan") }
            }
        }

        // Available networks list
        ContentSubsection {
            title: Translation.tr("Available networks")
            visible: Network.wifiEnabled

            Repeater {
                model: Network.friendlyWifiNetworks
                delegate: RippleButton {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52
                    buttonRadius: Appearance.rounding.normal
                    colBackground: modelData.active ? Appearance.colors.colPrimaryContainer : "transparent"
                    onClicked: {
                        if (!modelData.active) Network.connectToWifiNetwork(modelData)
                    }
                    contentItem: RowLayout {
                        anchors { fill: parent; margins: 10 }
                        spacing: 10
                        MaterialSymbol {
                            text: modelData.strength > 67 ? "signal_wifi_4_bar" :
                                  modelData.strength > 33 ? "network_wifi_3_bar" : "network_wifi_1_bar"
                            iconSize: 18
                            color: modelData.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.ssid
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: modelData.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer0
                        }
                        MaterialSymbol {
                            visible: modelData.security.length > 0
                            text: "lock"; iconSize: 14
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            visible: modelData.active
                            text: Translation.tr("Connected")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "lan"
        title: Translation.tr("Ethernet")

        StyledText {
            text: Network.ethernet ? Translation.tr("Ethernet is connected") : Translation.tr("No ethernet connection")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer0
        }
    }

    ContentSection {
        icon: "open_in_new"
        title: Translation.tr("Actions")

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "settings_ethernet"
            mainText: Translation.tr("Open full network manager")
            buttonRadius: Appearance.rounding.small
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.network])
        }
    }
}
