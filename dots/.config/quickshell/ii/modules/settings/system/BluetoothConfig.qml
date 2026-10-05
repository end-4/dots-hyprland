import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property bool scanRequested: false
    readonly property bool bluetoothAvailable: BluetoothStatus.available
    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool bluetoothScanning: Bluetooth.defaultAdapter?.discovering ?? false
    readonly property int savedDeviceCount: BluetoothStatus.connectedDevices.length + BluetoothStatus.pairedButNotConnectedDevices.length

    function scanDevices() {
        if (!Bluetooth.defaultAdapter)
            return;

        scanRequested = true;
        if (!Bluetooth.defaultAdapter.enabled)
            Bluetooth.defaultAdapter.enabled = true;
        Bluetooth.defaultAdapter.discovering = true;
    }

    function stopScanning() {
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering)
            Bluetooth.defaultAdapter.discovering = false;
    }

    function resetScanState() {
        root.stopScanning();
        root.scanRequested = false;
    }

    onBluetoothEnabledChanged: {
        if (!bluetoothEnabled)
            root.resetScanState();
    }

    Component.onDestruction: root.stopScanning()

    onVisibleChanged: {
        if (!visible)
            root.stopScanning();
    }

    component BluetoothSettingsDeviceItem: DialogListItem {
        id: itemRoot
        required property var device
        property bool nearby: false

        Layout.fillWidth: true
        verticalPadding: 8
        buttonRadius: Appearance.rounding.normal
        pointingHandCursor: false

        contentItem: RowLayout {
            anchors {
                fill: parent
                topMargin: itemRoot.verticalPadding
                bottomMargin: itemRoot.verticalPadding
                leftMargin: itemRoot.horizontalPadding
                rightMargin: itemRoot.horizontalPadding
            }
            spacing: 10

            MaterialSymbol {
                text: Icons.getBluetoothDeviceMaterialSymbol(itemRoot.device?.icon || "")
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: itemRoot.device?.name || Translation.tr("Unknown device")
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (itemRoot.nearby)
                            return Translation.tr("Available to pair");

                        let statusText = itemRoot.device?.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (itemRoot.device?.batteryAvailable)
                            statusText += ` - ${Math.round(itemRoot.device?.battery * 100)}%`;
                        return statusText;
                    }
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    elide: Text.ElideRight
                }
            }

            DialogButton {
                visible: !itemRoot.nearby
                buttonText: itemRoot.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
                onClicked: {
                    if (itemRoot.device?.connected)
                        itemRoot.device.disconnect();
                    else
                        itemRoot.device.connect();
                }
            }

            DialogButton {
                visible: !itemRoot.nearby
                buttonText: Translation.tr("Forget")
                colText: Appearance.colors.colError
                onClicked: itemRoot.device?.forget()
            }

            DialogButton {
                visible: itemRoot.nearby
                buttonText: Translation.tr("Pair")
                enabled: root.bluetoothEnabled
                onClicked: itemRoot.device?.pair()
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            OptionalMaterialSymbol {
                icon: BluetoothStatus.connected ? "bluetooth_connected" : root.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Bluetooth")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }

            DialogButton {
                buttonText: Translation.tr("Advanced settings")
                onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.bluetooth])
            }
        }

        ConfigSwitch {
            visible: root.bluetoothAvailable
            buttonIcon: root.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
            text: root.bluetoothEnabled ? Translation.tr("Bluetooth enabled") : Translation.tr("Bluetooth disabled")
            checked: root.bluetoothEnabled
            onCheckedChanged: {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = checked;
                    if (!checked)
                        Bluetooth.defaultAdapter.discovering = false;
                }
            }
        }

        ConfigRow {
            visible: root.bluetoothAvailable && root.bluetoothEnabled

            DialogButton {
                buttonText: root.bluetoothScanning ? Translation.tr("Scanning") : Translation.tr("Scan")
                enabled: !root.bluetoothScanning
                onClicked: root.scanDevices()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.bluetoothAvailable
            text: Translation.tr("No Bluetooth adapter found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }
    }

    ContentSection {
        id: nearbySection
        visible: root.bluetoothEnabled && (root.scanRequested || opacity > 0)
        property real animatedHeight: root.bluetoothEnabled && root.scanRequested ? implicitHeight : 0
        Layout.maximumHeight: animatedHeight
        clip: true
        opacity: root.scanRequested ? 1 : 0
        icon: "travel_explore"
        title: Translation.tr("Nearby devices")

        Behavior on animatedHeight {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.bluetoothScanning && BluetoothStatus.unpairedDevices.length === 0
            text: Translation.tr("Scanning for devices...")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.bluetoothScanning && BluetoothStatus.unpairedDevices.length === 0
            text: Translation.tr("No nearby devices found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: ScriptModel {
                values: BluetoothStatus.unpairedDevices
            }

            BluetoothSettingsDeviceItem {
                required property BluetoothDevice modelData
                device: modelData
                nearby: true
            }
        }
    }

    ContentSection {
        visible: root.bluetoothEnabled
        icon: "bookmark"
        title: Translation.tr("Saved devices")

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            text: root.savedDeviceCount === 1
                ? Translation.tr("1 saved Bluetooth device")
                : Translation.tr("%1 saved Bluetooth devices").arg(root.savedDeviceCount)
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.savedDeviceCount === 0
            text: Translation.tr("No paired Bluetooth devices found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: ScriptModel {
                values: [
                    ...BluetoothStatus.connectedDevices,
                    ...BluetoothStatus.pairedButNotConnectedDevices
                ]
            }

            BluetoothSettingsDeviceItem {
                required property BluetoothDevice modelData
                device: modelData
            }
        }
    }
}
