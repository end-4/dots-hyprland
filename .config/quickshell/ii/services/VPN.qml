pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * VPN service
 */
Singleton {
    id: root

    property bool connected: false
    property bool available: false
    property int updateInterval: 1000
    property string vpnName: ""
    property string materialSymbol: VPN.connected ? "vpn_key" : "vpn_key_off"
    function update() {
        updateVPNActive.startCheck();
        updateVPNName.running = true;
        updateVPNAvailable.running = true;
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            root.update();
            interval = root.updateInterval;
        }
    }

    Process {
        id: updateVPNActive
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE c show --active"]
        running: true
        function startCheck() {
            buffer = "";
            updateVPNActive.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateVPNActive.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateVPNActive.buffer.trim().split('\n');
            let isConnected = false
            lines.forEach(line => {
                if (line.includes("vpn"))
                    isConnected = true;
                else if (line.includes("wireguard"))
                    isConnected = true;
            });
            root.connected = isConnected;
        }
    }

    Process {
        id: updateVPNName
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE c show --active | awk -F: 'BEGIN {found=0} $2 == \"vpn\" || $2 == \"wireguard\" {print $1; found=1} END {if (found == 0) print \"\"}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
            	if (data.trim() == "") {
            		root.vpnName = "Disconnected"
            	} else {
                	root.vpnName = data.trim();
                }
            }
        }
    }

    Process {
    	id: updateVPNAvailable
    	command: ["sh", "-c", "command -v protonvpn-app"]
    	running: true
    	onExited: (exitCode, exitStatus) => {
    	   root.available = exitCode === 0
    	}
    }
}
