pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)
}
