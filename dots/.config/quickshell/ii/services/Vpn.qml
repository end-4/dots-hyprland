pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

// Discovers all VPN and WireGuard connections from NetworkManager.
// Each entry: { name: string, connectionType: "vpn"|"wireguard", active: bool }
// Piggybacks on Network's existing nmcli monitor instead of spawning its own.
// All activity stops when enableVpnToggles is turned off in config.
Singleton {
    id: root

    property var connections: []
    property bool nmRunning: true

    readonly property bool enabled: Config.ready && Config.options.sidebar.quickToggles.enableVpnToggles

    onEnabledChanged: {
        if (enabled) {
            scanProcess.running = true
        } else {
            scanProcess.running = false
            retryTimer.stop()
            root.connections = []
        }
    }

    function connectionFor(name) {
        return root.connections.find(c => c.name === name) ?? null
    }

    // Reuse Network's already-running nmcli monitor
    Connections {
        target: Network
        enabled: root.enabled
        function onMonitorChanged() {
            scanProcess.running = true
        }
    }

    // When a scan returns 0 VPN connections but we previously had some,
    // NetworkManager likely just restarted and hasn't re-registered
    // connections yet. Retry a few times with a delay.
    Timer {
        id: retryTimer
        property int retries: 0
        interval: 1500
        repeat: true
        onTriggered: {
            scanProcess.running = true
            retries++
            if (retries >= 5) {
                // NM is not coming back — accept it's down
                stop()
                root.nmRunning = false
                root.connections = root.connections.map(c => ({ name: c.name, connectionType: c.connectionType, active: false }))
            }
        }
    }

    // List all connections and their current state in one pass.
    // Parse from the end of each line so colons inside connection names
    // (which nmcli escapes as \:) don't break the split.
    Process {
        id: scanProcess
        running: root.enabled
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // nmcli failed — NM is not running
                root.nmRunning = false
                root.connections = root.connections.map(c => ({ name: c.name, connectionType: c.connectionType, active: false }))
            }
        }
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
                if (newConns.length === 0 && root.connections.length > 0) {
                    // NM likely restarting — keep old connections and retry
                    if (!retryTimer.running) {
                        retryTimer.retries = 0
                        retryTimer.start()
                    }
                } else {
                    retryTimer.stop()
                    root.nmRunning = true
                    root.connections = newConns
                }
            }
        }
    }
}
