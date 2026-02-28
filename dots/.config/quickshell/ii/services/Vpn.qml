pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

// Discovers all VPN and WireGuard connections from NetworkManager.
// Each entry: { name: string, connectionType: "vpn"|"wireguard", active: bool }
// All processes are stopped when enableVpnToggles is turned off in config.
Singleton {
    id: root

    property var connections: []

    readonly property bool enabled: Config.ready && Config.options.sidebar.quickToggles.enableVpnToggles

    onEnabledChanged: {
        if (enabled) {
            scanProcess.running = true
        } else {
            monitorProcess.running = false
            scanProcess.running = false
            root.connections = []
        }
    }

    function connectionFor(name) {
        return root.connections.find(c => c.name === name) ?? null
    }

    function update() {
        if (root.enabled) scanProcess.running = true
    }

    // List all connections and their current state in one pass.
    // Parse from the end of each line so colons inside connection names
    // (which nmcli escapes as \:) don't break the split.
    Process {
        id: scanProcess
        running: root.enabled
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const newConns = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const lastColon = line.lastIndexOf(":")
                    if (lastColon < 0) continue
                    const secondLastColon = line.lastIndexOf(":", lastColon - 1)
                    if (secondLastColon < 0) continue
                    const name = line.substring(0, secondLastColon).replace(/\\:/g, ":")
                    const connType = line.substring(secondLastColon + 1, lastColon)
                    const state = line.substring(lastColon + 1)
                    if (connType === "vpn" || connType === "wireguard") {
                        newConns.push({ name, connectionType: connType, active: state === "activated" })
                    }
                }
                root.connections = newConns
                // Start monitoring only after the first successful scan
                if (!monitorProcess.running) monitorProcess.running = true
            }
        }
    }

    Process {
        id: monitorProcess
        running: false
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }
}
