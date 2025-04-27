pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import Quickshell.Services.Pipewire;
import QtQuick;

Singleton {
    id: root

    property int updateInterval: 1000
    property string networkName: "";
    property int    networkStrength;
    function update() {
        updateNetworkName.running = true
        updateNetworkStrength.running = true
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            update()
            interval = root.updateInterval;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true;
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}'"];
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }
}

