pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    // BlueZ doesn't save whether Bluetooth is on and powers it on at boot (AutoEnable),
    // so remember it here, whichever app switches it, and restore it once per login
    property bool restored: false
    function restoreEnabled() {
        if (root.restored || !Persistent.ready || !Bluetooth.defaultAdapter) return;
        root.restored = true;
        if (!Persistent.isNewHyprlandInstance) // The shell restarted: keep what it is now
            Persistent.states.bluetooth.enabled = Bluetooth.defaultAdapter.enabled;
        else if (!Persistent.states.bluetooth.enabled)
            Bluetooth.defaultAdapter.enabled = false;
    }
    function load() {} // (shell.qml: so it restores at login with no bar to show it)
    Component.onCompleted: restoreEnabled()
    onAvailableChanged: restoreEnabled()
    Connections {
        target: Persistent
        function onReadyChanged() {
            Qt.callLater(root.restoreEnabled);
        }
    }
    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() {
            if (!root.restored) return;
            Persistent.states.bluetooth.enabled = Bluetooth.defaultAdapter.enabled;
        }
    }

    function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }
    property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    property list<var> pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    property list<var> unpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]
}
