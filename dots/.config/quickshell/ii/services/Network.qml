pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false
    // Connected through ethernet, but it doesn't reach the internet
    property bool ethernetLimited: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"

    property list<var> activeConnections: []
    // Name of the connection the icon stands for. Loopback and bridges (docker, libvirt...) can be listed first
    readonly property string networkName: {
        const preferredType = root.ethernet ? "802-3-ethernet" : "802-11-wireless";
        const ignoredTypes = ["loopback", "bridge", "tun", "dummy"];
        const connection = activeConnections.find(c => c.type === preferredType)
            ?? activeConnections.find(c => !ignoredTypes.includes(c.type));
        return connection?.name ?? "";
    }
    readonly property int networkStrength: active?.strength ?? 0
    property string materialSymbol: root.ethernet
        ? (root.ethernetLimited ? "public_off" : "lan")
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        // We use this instead of `nmcli connection up SSID` because this also creates a connection profile
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid])

    }

    function disconnectWifiNetwork(): void {
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        // TODO: enterprise wifi with username
        network.askingPassword = false;
        changePasswordProc.exec({
            "environment": {
                "PASSWORD": password,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", 'nmcli connection modify "$SSID" wifi-sec.psk "$PASSWORD"']
        })
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                // print(line)
                getNetworks.running = true
            }
        }
        stderr: SplitParser {
            onRead: line => {
                // print("err:", line)
                if (line.includes("Secrets were required")) {
                    root.wifiConnectTarget.askingPassword = true
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.wifiConnectTarget.askingPassword = (exitCode !== 0)
            root.wifiConnectTarget = null
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: changePasswordProc
        onExited: { // Re-attempt connection after changing password
            connectProc.running = false
            connectProc.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // Status update
    // `nmcli monitor` prints several lines per state change, so they're coalesced into one refresh
    function update() {
        updateDebounce.restart();
    }

    Timer {
        id: updateDebounce
        interval: 300
        onTriggered: {
            updateConnectionType.running = true;
            wifiStatusProcess.running = true;
            updateNetworkName.running = true;
            getNetworks.running = true;
        }
    }

    // `nmcli monitor` reports neither signal changes nor the connectivity of each device. Reading them is cheap
    // and doesn't touch the radio, as NM keeps the strength of the current access point up to date by itself
    Timer {
        readonly property bool wifiAssociated: root.wifiStatus === "connected" || root.wifiStatus === "limited"
        interval: 10000
        repeat: true
        running: root.ethernet || wifiAssociated
        onTriggered: {
            updateConnectionType.running = true;
            if (wifiAssociated)
                getNetworks.running = true;
        }
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    // Whether a device reaches the internet, from NetworkManager's per-device connectivity check.
    // The device's connectivity is the best of IPv4 and IPv6 (one is often "limited" or "none" for lack of IPv6).
    // "unknown" means the check is disabled or hasn't finished, so it's not reported as a problem
    function hasInternet(ip4Connectivity: string, ip6Connectivity: string): bool {
        const rank = ["unknown", "none", "portal", "limited", "full"];
        const best = Math.max(rank.indexOf(ip4Connectivity), rank.indexOf(ip6Connectivity));
        return best <= 0 || best === rank.length - 1;
    }

    Process {
        id: updateConnectionType
        command: ["nmcli", "-t", "-f", "TYPE,STATE,IP4-CONNECTIVITY,IP6-CONNECTIVITY", "d", "status"]
        running: true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                let hasEthernet = false;
                let ethernetOnline = false;
                let hasWifi = false;
                let wifiStatus = "disconnected";
                text.trim().split("\n").forEach(line => {
                    const [type, state = "", ip4Connectivity = "", ip6Connectivity = ""] = line.split(":");
                    // "disconnected" also contains "connected"
                    if (type === "ethernet" && state.startsWith("connected")) {
                        hasEthernet = true;
                        if (root.hasInternet(ip4Connectivity, ip6Connectivity))
                            ethernetOnline = true;
                    }
                    else if (type === "wifi") {
                        if (state.startsWith("disconnected")) {
                            wifiStatus = "disconnected"
                        }
                        else if (state.startsWith("connected")) {
                            hasWifi = true;
                            wifiStatus = "connected"

                            if (!root.hasInternet(ip4Connectivity, ip6Connectivity)) {
                                hasWifi = false;
                                wifiStatus = "limited"
                            }
                        }
                        else if (state.startsWith("connecting")) {
                            wifiStatus = "connecting"
                        }
                        else if (state.startsWith("unavailable")) {
                            wifiStatus = "disabled"
                        }
                    }
                });
                root.wifiStatus = wifiStatus;
                // An ethernet link without internet (e.g. straight to another computer) is only shown when wifi
                // doesn't have internet either: NetworkManager then routes the traffic through wifi
                root.ethernet = hasEthernet && (ethernetOnline || !hasWifi);
                root.ethernetLimited = root.ethernet && !ethernetOnline;
                root.wifi = hasWifi;
            }
        }
    }

    Process {
        id: updateNetworkName
        command: ["nmcli", "-t", "--escape", "no", "-f", "TYPE,NAME", "c", "show", "--active"]
        running: true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeConnections = text.trim().split("\n").map(line => {
                    const separator = line.indexOf(":");
                    return {
                        type: line.slice(0, separator),
                        name: line.slice(separator + 1)
                    };
                }).filter(c => c.name.length > 0);
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        // `--rescan no`: by default nmcli scans when the list is older than 30s, which stalls the connection for a few seconds
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w", "list", "--rescan", "no"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}
