import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "connectivity"

Item {
    id: root
    // Read initialTab from the root ApplicationWindow (for deep-linking)
    property int initialTab: {
        const win = Window.window;
        return win?.initialTab ?? 0;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SecondaryTabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 10
            currentIndex: root.initialTab

            SecondaryTabButton {
                buttonIcon: "wifi"
                buttonText: Translation.tr("Wi-Fi")
            }
            SecondaryTabButton {
                buttonIcon: "bluetooth"
                buttonText: Translation.tr("Bluetooth")
            }
        }

        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            clip: true

            onCurrentIndexChanged: {
                tabBar.currentIndex = swipeView.currentIndex;
            }

            Loader {
                active: SwipeView.isCurrentItem || SwipeView.isPreviousItem || SwipeView.isNextItem
                sourceComponent: WifiView {}
            }

            Loader {
                active: SwipeView.isCurrentItem || SwipeView.isPreviousItem || SwipeView.isNextItem
                sourceComponent: BluetoothView {}
            }
        }
    }

    component WifiView: Item {
        id: wifiView
        
        ContentPage {
            anchors.fill: parent
            forceWidth: true
            
            ContentSection {
                icon: "wifi"
                title: Translation.tr("Wi-Fi")
                
                headerExtra: [
                    RippleButton {
                        visible: Network.wifiEnabled
                        implicitWidth: 90
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: Network.rescanWifi()
                        
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "refresh"
                                iconSize: 16
                                color: Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                text: Translation.tr("Scan")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer2
                            }
                        }
                    }
                ]
                
                ConfigRow {
                    ConfigSwitch {
                        text: Translation.tr("Enable Wi-Fi")
                        checked: Network.wifiEnabled
                        onCheckedChanged: {
                            Network.enableWifi(checked);
                        }
                    }
                }
                
                StyledIndeterminateProgressBar {
                    visible: Network.wifiScanning
                    Layout.fillWidth: true
                }
            }
            
            ContentSection {
                icon: "wifi_find"
                title: Translation.tr("Available Networks")
                visible: Network.wifiEnabled
                
                // Empty state
                ColumnLayout {
                    visible: Network.friendlyWifiNetworks.length === 0 && !Network.wifiScanning
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    spacing: 8
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 64
                        implicitHeight: 64
                        radius: 32
                        color: Appearance.colors.colLayer3
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "wifi_find"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No networks found")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Click Scan to search for networks")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                // Network list
                Repeater {
                    model: Network.friendlyWifiNetworks
                    
                    ConnectivityWifiItem {
                        required property var modelData
                        wifiNetwork: modelData
                        Layout.fillWidth: true
                    }
                }
            }
            
            ContentSection {
                icon: "wifi_add"
                title: Translation.tr("Hidden Network")
                visible: Network.wifiEnabled
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    MaterialTextField {
                        id: hiddenSsidField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Network name (SSID)")
                    }
                    
                    MaterialTextField {
                        id: hiddenPasswordField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Password (optional)")
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData
                    }
                    
                    RippleButton {
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: 140
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.full
                        enabled: hiddenSsidField.text.length > 0
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        
                        onClicked: {
                            const ssid = hiddenSsidField.text;
                            const password = hiddenPasswordField.text;
                            if (password.length > 0) {
                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
                            } else {
                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
                            }
                            hiddenSsidField.text = "";
                            hiddenPasswordField.text = "";
                        }
                        
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnPrimary
                            }
                            StyledText {
                                text: Translation.tr("Connect")
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }
    }

    component BluetoothView: Item {
        id: bluetoothView
        
        ContentPage {
            anchors.fill: parent
            forceWidth: true
            
            ContentSection {
                icon: "bluetooth"
                title: Translation.tr("Bluetooth")
                
                headerExtra: [
                    RippleButton {
                        visible: Bluetooth.defaultAdapter?.enabled ?? false
                        implicitWidth: 90
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: Bluetooth.defaultAdapter?.discovering ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        colBackgroundHover: Bluetooth.defaultAdapter?.discovering ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        onClicked: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
                            }
                        }
                        
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: Bluetooth.defaultAdapter?.discovering ? "stop" : "bluetooth_searching"
                                iconSize: 16
                                color: Bluetooth.defaultAdapter?.discovering ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                text: Bluetooth.defaultAdapter?.discovering ? Translation.tr("Stop") : Translation.tr("Scan")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Bluetooth.defaultAdapter?.discovering ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                            }
                        }
                    }
                ]
                
                ConfigRow {
                    ConfigSwitch {
                        text: Translation.tr("Enable Bluetooth")
                        checked: Bluetooth.defaultAdapter?.enabled ?? false
                        onCheckedChanged: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = checked;
                            }
                        }
                    }
                }
                
                // Discoverable toggle
                ConfigRow {
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    
                    ConfigSwitch {
                        text: Translation.tr("Discoverable")
                        checked: Bluetooth.defaultAdapter?.discoverable ?? false
                        onCheckedChanged: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.discoverable = checked;
                            }
                        }
                    }
                }
                
                // Pairable toggle
                ConfigRow {
                    visible: Bluetooth.defaultAdapter?.enabled ?? false
                    
                    ConfigSwitch {
                        text: Translation.tr("Pairable")
                        checked: Bluetooth.defaultAdapter?.pairable ?? false
                        onCheckedChanged: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.pairable = checked;
                            }
                        }
                    }
                }
                
                StyledIndeterminateProgressBar {
                    visible: Bluetooth.defaultAdapter?.discovering ?? false
                    Layout.fillWidth: true
                }
            }
            
            // Connected devices
            ContentSection {
                icon: "bluetooth_connected"
                title: Translation.tr("Connected Devices")
                visible: (Bluetooth.defaultAdapter?.enabled ?? false) && BluetoothStatus.connectedDevices.length > 0
                
                Repeater {
                    model: BluetoothStatus.connectedDevices
                    
                    ConnectivityBluetoothItem {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Paired devices
            ContentSection {
                icon: "bluetooth"
                title: Translation.tr("Paired Devices")
                visible: (Bluetooth.defaultAdapter?.enabled ?? false) && BluetoothStatus.pairedButNotConnectedDevices.length > 0
                
                Repeater {
                    model: BluetoothStatus.pairedButNotConnectedDevices
                    
                    ConnectivityBluetoothItem {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Available devices
            ContentSection {
                icon: "devices"
                title: Translation.tr("Available Devices")
                visible: (Bluetooth.defaultAdapter?.enabled ?? false)
                
                // Empty state - center it properly
                Item {
                    visible: BluetoothStatus.friendlyDeviceList.length === 0 && !(Bluetooth.defaultAdapter?.discovering ?? false)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 72
                            implicitHeight: 72
                            radius: 36
                            color: Appearance.colors.colLayer3
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "bluetooth_searching"
                                iconSize: 36
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("No devices found")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer2
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("Click Scan to discover nearby devices")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                
                Repeater {
                    model: BluetoothStatus.unpairedDevices
                    
                    ConnectivityBluetoothItem {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
