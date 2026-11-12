pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.ii.island

// Flashes when a Bluetooth device connects or disconnects.
Item {
    id: root

    // address -> name of every device connected at the last sync.
    property var known: ({})
    // Device lists fill in asynchronously after startup; changes before this
    // is set only update `known`, so auto-reconnects at login don't flash.
    property bool settled: false

    Timer {
        id: settleTimer
        interval: 5000
        running: true
        onTriggered: root.settled = true
    }

    Component.onCompleted: root.sync()

    Connections {
        target: BluetoothStatus
        function onConnectedDevicesChanged() { root.sync(); }
    }

    function sync(): void {
        const devices = BluetoothStatus.connectedDevices;
        const current = {};
        for (const d of devices)
            current[d.address] = d.name;

        if (root.settled) {
            for (const d of devices) {
                if (!(d.address in root.known))
                    root.flashConnected(d);
            }
            for (const addr in root.known) {
                if (!(addr in current))
                    root.flashDisconnected(root.known[addr]);
            }
        }
        root.known = current;
    }

    function flashConnected(d: var): void {
        const isAudio = /audio|headset|headphone/i.test(d.icon ?? "");
        let text = d.name;
        if (d.batteryAvailable && isFinite(d.battery))
            text += " · " + Math.round(d.battery * 100) + "%";
        IslandState.flash(isAudio ? "headphones" : "bluetooth", text, { ms: 2000 });
    }

    function flashDisconnected(name: string): void {
        IslandState.flash("bluetooth_disabled", Translation.tr("%1 disconnected").arg(name), { ms: 2000 });
    }
}
