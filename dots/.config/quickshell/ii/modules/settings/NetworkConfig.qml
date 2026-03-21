import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "wifi"
        title: Translation.tr("Network Status")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                iconSize: 28
                text: Network.ethernet ? "lan" : (Network.wifi ? "signal_wifi_4_bar" : "wifi_off")
                color: Network.wifi || Network.ethernet ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Network.ethernet ? Translation.tr("Ethernet")
                        : Network.wifi ? Translation.tr("Wi‑Fi connected")
                        : Network.wifiStatus === "connecting" ? Translation.tr("Connecting...")
                        : Network.wifiStatus === "disabled" ? Translation.tr("Wi‑Fi disabled")
                        : Translation.tr("Disconnected")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    visible: Network.wifi || Network.ethernet
                    text: Network.networkName || Translation.tr("Connected")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "wifi"
            text: Translation.tr("Wi‑Fi")
            checked: Network.wifiEnabled
            onCheckedChanged: Network.enableWifi(checked)
        }

        RowLayout {
            spacing: 8
            RippleButtonWithIcon {
                visible: Network.wifiEnabled
                materialIcon: "sync"
                mainText: Translation.tr("Rescan")
                enabled: !Network.wifiScanning
                onClicked: Network.rescanWifi()
            }
            RippleButtonWithIcon {
                materialIcon: "settings_ethernet"
                mainText: Translation.tr("Network settings")
                onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.network || "nm-connection-editor"])
                StyledToolTip { text: Translation.tr("Opens your system's network manager") }
            }
        }
    }

    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Wi‑Fi Networks")
        visible: Network.wifiEnabled

        ContentSubsection {
            title: Translation.tr("Available networks")
            tooltip: Translation.tr("Connect or disconnect from Wi‑Fi networks")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: ScriptModel { values: Network.friendlyWifiNetworks }

                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: wifiContent.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: wifiHover.containsMouse ? Appearance.colors.colLayer1 : "transparent"

                            ColumnLayout {
                                id: wifiContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    MaterialSymbol {
                                        iconSize: 22
                                        text: modelData.active ? "wifi" : (modelData.strength > 67 ? "signal_wifi_4_bar" : modelData.strength > 33 ? "network_wifi_2_bar" : "signal_wifi_1_bar")
                                        color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        StyledText {
                                            text: modelData.ssid || Translation.tr("Hidden network")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: modelData.active ? Font.Medium : Font.Normal
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                        StyledText {
                                            visible: !modelData.active
                                            text: (modelData.security ? Translation.tr("Secured") + " • " : "") + (modelData.strength || 0) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    RippleButton {
                                        visible: modelData.active
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        buttonRadius: Appearance.rounding.small
                                        onClicked: Network.disconnectWifiNetwork()
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            iconSize: 20
                                            text: "link_off"
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                    }

                                    RippleButton {
                                        visible: !modelData.active && !modelData.askingPassword
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        buttonRadius: Appearance.rounding.small
                                        enabled: !Network.wifiConnecting
                                        onClicked: Network.connectToWifiNetwork(modelData)
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            iconSize: 20
                                            text: "link"
                                            color: Appearance.colors.colPrimary
                                        }
                                    }
                                }

                                // Inline password prompt
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: modelData.askingPassword
                                    spacing: 8

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.colors.colOutline; opacity: 0.2 }
                                    MaterialTextField {
                                        id: passwordField
                                        Layout.fillWidth: true
                                        placeholderText: Translation.tr("Password")
                                        echoMode: TextInput.Password
                                        inputMethodHints: Qt.ImhSensitiveData
                                        onAccepted: {
                                            Network.changePassword(modelData, text);
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Item { Layout.fillWidth: true }
                                        DialogButton {
                                            buttonText: Translation.tr("Cancel")
                                            onClicked: modelData.askingPassword = false
                                        }
                                        DialogButton {
                                            buttonText: Translation.tr("Connect")
                                            onClicked: {
                                                Network.changePassword(modelData, passwordField.text);
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (!modelData.active && !modelData.askingPassword && !modelData.isSecure)
                                        Network.connectToWifiNetwork(modelData);
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: Network.friendlyWifiNetworks.length === 0 && !Network.wifiScanning
                    text: Translation.tr("No networks found. Try rescanning.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    visible: Network.wifiScanning
                    text: Translation.tr("Scanning...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
