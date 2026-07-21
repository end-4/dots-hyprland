import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    
    property list<string> vpnList: []

    property Process discoveryProc: Process {
        id: proc
        running: true
        // List all connections, filter for vpn or wireguard type, output only NAME
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE connection show | grep -E ':(vpn|wireguard)$' | cut -d: -f1"]
        
        stdout: StdioCollector {
            onTextChanged: {
                var lines = text.trim().split("\n")
                var newList = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length > 0) {
                        newList.push("vpn:" + line)
                    }
                }
                root.vpnList = newList
            }
        }
        
        // Refresh occasionally (e.g. every 10 seconds)
        // Or we could rely on a one-time fetch if we don't expect frequent changes
        // For now let's just run it once. If dynamic updates are needed we can add a timer/loop.
    }
}
