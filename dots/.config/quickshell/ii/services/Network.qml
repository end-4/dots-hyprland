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
    
    // Map of SSID -> [UUIDs] for saved connection profiles
    // Used for reliable deletion by UUID instead of by name
    property var savedConnectionsMap: ({})

    property string networkName: ""
    property int networkStrength
    property string materialSymbol: root.ethernet
        ? "lan"
        : root.wifiEnabled
            ? (
                Network.networkStrength > 83 ? "signal_wifi_4_bar" :
                Network.networkStrength > 67 ? "network_wifi" :
                Network.networkStrength > 50 ? "network_wifi_3_bar" :
                Network.networkStrength > 33 ? "network_wifi_2_bar" :
                Network.networkStrength > 17 ? "network_wifi_1_bar" :
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
        accessPoint.connectionError = "";  // Clear any previous error
        root.wifiConnectTarget = accessPoint;
        // We use this instead of `nmcli connection up SSID` because this also creates a connection profile
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid]);
    }

    function disconnectWifiNetwork(): void {
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    // Holy shit this was a nightmare to debug. NetworkManager creates ghost profiles,
    // nmcli lies about what it deletes, and UUIDs are the only truth in this world.
    // We fetch UUIDs from savedConnectionsMap and delete each one. F*** you, key-mgmt errors.
    function forgetWifiNetwork(accessPoint: WifiAccessPoint): void {
        const ssid = accessPoint.ssid;
        const uuids = root.savedConnectionsMap[ssid];
        
        if (!uuids || uuids.length === 0) {
            // No profiles? Refresh the map and pray
            getConnections.running = true;
            return;
        }
        
        // Delete each UUID - finally, something that actually works f me this mtf is hard
        for (const uuid of uuids) {
            forgetProc.exec(["nmcli", "connection", "delete", uuid]);
        }
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    // After hours of debugging, we discovered:
    // 1. Failed connections create broken profiles
    // 2. nmcli tries to reuse broken profiles instead of creating new ones
    // 3. The only solution: DELETE EVERYTHING and start fresh. Beautiful.
    function providePass(network: WifiAccessPoint, password: string, username = ""): void {
        // TODO: enterprise wifi with username
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        // Nuke any existing profiles, then connect with fresh credentials
        // This is the ONLY way to avoid the cursed "key-mgmt: property is missing" error
        connectWithPasswordProc.exec({
            "environment": {
                "LANG": "C",
                "LC_ALL": "C",
                "WIFI_SSID": network.ssid,
                "WIFI_PASSWORD": password
            },
            "command": ["bash", "-c", "nmcli connection delete \"$WIFI_SSID\" 2>/dev/null; nmcli dev wifi connect \"$WIFI_SSID\" password \"$WIFI_PASSWORD\""]
        });
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        property string lastError: ""
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                connectProc.lastError = line;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.wifiConnectTarget) {
                const err = connectProc.lastError;
                // Password/secrets errors -> show password prompt
                if (err.includes("Secrets were required") || err.includes("psk") || err.includes("password")) {
                    root.wifiConnectTarget.askingPassword = true;
                    root.wifiConnectTarget.connectionError = "";
                }
                // Network not found
                else if (err.includes("No network") || err.includes("not found")) {
                    root.wifiConnectTarget.connectionError = "Network not found";
                }
                // Device busy
                else if (err.includes("busy") || err.includes("in use")) {
                    root.wifiConnectTarget.connectionError = "Device busy, try again";
                }
                // Generic error
                else {
                    root.wifiConnectTarget.connectionError = "Connection failed";
                }
            } else if (root.wifiConnectTarget) {
                // Success - clear any previous error
                root.wifiConnectTarget.connectionError = "";
            }
            root.wifiConnectTarget = null;
            connectProc.lastError = "";
        }
    }

    // This bad boy finally works after we figured out the environment variable nightmare
    Process {
        id: connectWithPasswordProc
        property string lastError: ""
        stdout: SplitParser {
            onRead: line => {}
        }
        stderr: SplitParser {
            onRead: line => {
                connectWithPasswordProc.lastError = line;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.wifiConnectTarget) {
                const err = connectWithPasswordProc.lastError;
                // Wrong password - show password prompt again
                if (err.includes("Secrets") || err.includes("psk") || err.includes("password") || err.includes("key-mgmt")) {
                    root.wifiConnectTarget.askingPassword = true;
                    root.wifiConnectTarget.connectionError = "Wrong password";
                }
                // Other errors - show error message, don't ask for password
                else if (err.includes("No network") || err.includes("not found")) {
                    root.wifiConnectTarget.connectionError = "Network not found";
                }
                else {
                    root.wifiConnectTarget.connectionError = "Connection failed";
                }
            } else if (root.wifiConnectTarget) {
                root.wifiConnectTarget.connectionError = "";
            }
            root.wifiConnectTarget = null;
            connectWithPasswordProc.lastError = "";
            getNetworks.running = true;
            getConnections.running = true;
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: forgetProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: line => {}
        }
        stderr: SplitParser {
            onRead: line => {}
        }
        onExited: (exitCode, exitStatus) => {
            // Victory lap - refresh everything
            getNetworks.running = true;
            getConnections.running = true;
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

    // Fetch saved connection profiles to build SSID -> UUID map
    Process {
        id: getConnections
        running: true
        command: ["nmcli", "-g", "NAME,UUID,TYPE", "connection", "show"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const newMap = {};
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    if (!line) continue;
                    // Format: NAME:UUID:TYPE (escaping handled by -t flag)
                    const parts = line.split(":");
                    if (parts.length >= 3) {
                        const name = parts[0];
                        const uuid = parts[1];
                        const type = parts[2];
                        // Only track wifi connections
                        if (type === "802-11-wireless") {
                            if (!newMap[name]) {
                                newMap[name] = [];
                            }
                            newMap[name].push(uuid);
                        }
                    }
                }
                root.savedConnectionsMap = newMap;
            }
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop() // none, limited, full
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });
            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
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
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
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
