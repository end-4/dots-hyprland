pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Basic polled Bluetooth state.
 */
Singleton {
    id: root

    property int updateInterval: 1000
    property string bluetoothDeviceName: ""
    property string bluetoothDeviceAddress: ""
    property bool bluetoothEnabled: false
    property bool bluetoothConnected: false

    function update() {
        updateBluetoothDevice.running = true
        updateBluetoothStatus.running = true
        updateBluetoothEnabled.running = true
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            update()
            interval = root.updateInterval
        }
    }

    // Check if Bluetooth is enabled (controller powered on)
    Process {
        id: updateBluetoothEnabled
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.bluetoothEnabled = (parseInt(data) === 1)
            }
        }
    }

    // Get the name and address of the first connected Bluetooth device
    Process {
        id: updateBluetoothDevice
        command: ["sh", "-c", "bluetoothctl info | awk -F': ' '/Name: /{name=$2} /Device /{addr=$2} END{print name \":\" addr}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.split(":")
                root.bluetoothDeviceName = parts[0] || ""
                root.bluetoothDeviceAddress = parts[1] || ""
            }
        }
    }

    // Check if any device is connected
    Process {
        id: updateBluetoothStatus
        command: ["sh", "-c", "bluetoothctl info | grep -q 'Connected: yes' && echo 1 || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.bluetoothConnected = (parseInt(data) === 1)
            }
        }
    }
}
