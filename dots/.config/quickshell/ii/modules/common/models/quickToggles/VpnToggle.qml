import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root

    property string vpnName: "VPN"

    readonly property var _conn: Vpn.connectionFor(vpnName)

    name: vpnName
    icon: _conn?.connectionType === "wireguard" ? "globe" : "vpn_key"
    statusText: root.toggled ? Translation.tr("Connected") : Translation.tr("Disconnected")
    tooltipText: Translation.tr("VPN · %1").arg(vpnName)

    available: _conn !== null
    toggled: _conn?.active ?? false

    mainAction: () => {
        if (root.toggled) {
            vpnDown.running = true
        } else {
            vpnUp.running = true
        }
    }

    Process {
        id: vpnUp
        command: ["nmcli", "connection", "up", root.vpnName]
        environment: ({ LANG: "C", LC_ALL: "C" })
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send",
                    root.vpnName,
                    Translation.tr("Failed to connect. Check your VPN configuration."),
                    "-a", "Shell"
                ])
            }
        }
    }

    Process {
        id: vpnDown
        command: ["nmcli", "connection", "down", root.vpnName]
        environment: ({ LANG: "C", LC_ALL: "C" })
    }
}
