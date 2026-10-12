pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false

    property list<var> connectedDevices: []
    property list<var> pairedButNotConnectedDevices: []
    property list<var> unpairedDevices: []
    property list<var> friendlyDeviceList: []

    readonly property BluetoothDevice firstActiveDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property int activeDeviceCount: connectedDevices.length
    readonly property bool connected: activeDeviceCount > 0

    onAvailableChanged: scheduleUpdate(true)
    onEnabledChanged: scheduleUpdate(true)

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() {
            root.scheduleUpdate(true);
        }
    }

    readonly property var macRegex: /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/

    function sortFunction(a, b) {
        if (!a || !b) return 0;
        const nameA = a.name || "";
        const nameB = b.name || "";
        const aIsMacOrEmpty = !nameA || root.macRegex.test(nameA);
        const bIsMacOrEmpty = !nameB || root.macRegex.test(nameB);
        if (aIsMacOrEmpty !== bIsMacOrEmpty)
            return aIsMacOrEmpty ? 1 : -1;

        // Alphabetical by name
        return nameA.localeCompare(nameB);
    }

    property string expandedAddress: ""
    onExpandedAddressChanged: {
        if (expandedAddress === "" && pendingUpdate) {
            pendingUpdate = false;
            updateFriendlyDeviceList();
        }
    }

    function areDeviceListsEqual(a, b) {
        if (a === b) return true;
        if (!a || !b || a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }

    property bool pendingUpdate: false

    Timer {
        id: updateThrottleTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.expandedAddress !== "") {
                root.pendingUpdate = true;
                updateThrottleTimer.start();
                return;
            }
            root.updateFriendlyDeviceList();
            if (root.pendingUpdate) {
                root.pendingUpdate = false;
                updateThrottleTimer.start();
            }
        }
    }

    function scheduleUpdate(immediate = false) {
        if (immediate) {
            updateThrottleTimer.stop();
            pendingUpdate = false;
            root.updateFriendlyDeviceList();
            return;
        }
        if (updateThrottleTimer.running) {
            pendingUpdate = true;
        } else {
            updateThrottleTimer.start();
        }
    }

    Connections {
        target: Bluetooth.devices
        function onValuesChanged() {
            root.scheduleUpdate(false);
        }
    }

    Instantiator {
        model: Bluetooth.devices

        Connections {
            required property BluetoothDevice modelData
            target: modelData

            function onConnectedChanged() {
                root.scheduleUpdate(true);
            }
            function onPairedChanged() {
                root.scheduleUpdate(true);
            }
        }
    }

    function updateFriendlyDeviceList() {
        if (!available || !enabled) {
            if (connectedDevices.length > 0) connectedDevices = [];
            if (pairedButNotConnectedDevices.length > 0) pairedButNotConnectedDevices = [];
            if (unpairedDevices.length > 0) unpairedDevices = [];
            if (friendlyDeviceList.length > 0) friendlyDeviceList = [];
            return;
        }
        const devices = Bluetooth.devices.values;
        const connected = devices.filter(d => d && d.connected).sort(sortFunction);
        const paired = devices.filter(d => d && d.paired && !d.connected).sort(sortFunction);
        const unpaired = devices.filter(d => d && !d.paired && !d.connected).sort(sortFunction);
        const friendly = [...connected, ...paired, ...unpaired];

        if (!areDeviceListsEqual(connectedDevices, connected))
            connectedDevices = connected;
        if (!areDeviceListsEqual(pairedButNotConnectedDevices, paired))
            pairedButNotConnectedDevices = paired;
        if (!areDeviceListsEqual(unpairedDevices, unpaired))
            unpairedDevices = unpaired;
        if (!areDeviceListsEqual(friendlyDeviceList, friendly))
            friendlyDeviceList = friendly;
    }

    Component.onCompleted: {
        updateFriendlyDeviceList();
    }
}
