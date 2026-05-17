import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

QuickToggleModel {
    id: root
    
    required property string connectionName

    name: connectionName
    toggled: false
    icon: "vpn_key"
    
    // Prevents status updates from overriding the optimistic UI state while an action is in progress
    property bool interacting: false

    mainAction: () => {
        if (root.interacting) return;
        
        root.interacting = true;
        if (toggled) {
            root.toggled = false // Optimistic
            actionProc.command = ["nmcli", "connection", "down", root.connectionName];
            actionProc.running = true;
        } else {
            root.toggled = true // Optimistic
            actionProc.command = ["nmcli", "connection", "up", root.connectionName];
            actionProc.running = true;
        }
    }

    // Processor for Up/Down commands
    Process {
        id: actionProc
        stdout: StdioCollector {
            onTextChanged: console.log("[VPN Log] " + text)
        }
        stderr: StdioCollector {
            onTextChanged: console.warn("[VPN Error] " + text)
        }
        onExited: (code) => {
            root.interacting = false;
            // If action failed, revert state
            if (code !== 0) {
                console.warn("VPN Action failed for " + root.connectionName + " with code " + code);
                // IF we were trying to connect (toggled=true), revert to false.
                // IF we were trying to disconnect (toggled=false), revert to true.
                // We can guess the intended state by inverting the currents state?
                // Actually, just trigger an immediate status check to confirm reality.
                statusTimer.triggered();
            } else {
                // Success. We could trigger a status check just to be sure.
                statusTimer.triggered();
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.interacting && !statusProc.running) {
                statusProc.running = true;
            }
        }
    }

    // One-shot status checker
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onTextChanged: {
                if (root.interacting) return;
                
                // output contains list of active connection names
                var active = text.split('\n').includes(root.connectionName);
                if (root.toggled !== active) {
                    root.toggled = active;
                }
            }
        }
    }
}
