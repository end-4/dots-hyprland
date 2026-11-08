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
    property bool wifiConnecting: currentConnectProc !== null
    property WifiAccessPoint wifiConnectTarget
    property var currentConnectProc: null
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

    property string networkName: ""
    property int networkStrength
    property string materialSymbol: root.ethernet
        ? "lan"
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

    // Bash function printing the UUID of a saved profile for $SSID (`find_profile --active` for an active one).
    // Matches the SSID rather than the profile name, which can differ (installer-made profiles, nmcli's
    // "SSID 1" duplicates)
    readonly property string findWifiProfileScript: `
        find_profile() {
            nmcli -t -f UUID,TYPE connection show "$@" | while IFS=: read -r uuid type; do
                [ "$type" = "802-11-wireless" ] || continue
                if [ "$(nmcli --escape no -g 802-11-wireless.ssid connection show uuid "$uuid")" = "$SSID" ]; then
                    echo "$uuid"
                    break
                fi
            done
        }
    `

    // Bash function bringing up profile $1 with $PASSWORD as its secret property $2. A password is never put on
    // a command line, where any local user can read it: it comes in the environment and is saved through
    // nmcli's editor on stdin, so that a wrong one fails right away like a wrong saved one. The editor drops
    // tabs and surrounding spaces though, so such passwords are handed over at activation with passwd-file
    // instead (which strips unescaped whitespace), where NetworkManager keeps retrying a wrong one until
    // nmcli gives up. The saved one is cleared first, or it would be retried until nmcli gives up; that
    // takes toggling the flags, as setting it to "" keeps it
    readonly property string connectWithPasswordScript: `
        passwd_file_value() {
            local v=\${1//\\\\/\\\\\\\\}
            v=\${v// /\\\\ }
            printf '%s' "\${v//$'\\t'/\\\\$'\\t'}"
        }
        connect_with_password() {
            case "$PASSWORD" in
                *$'\\t'* | " "* | *" ")
                    nmcli connection modify uuid "$1" "$2-flags" 2 && nmcli connection modify uuid "$1" "$2-flags" 0
                    # nmcli asks for the 802.1X identity along with the password
                    local identity=
                    [ "$2" = 802-1x.password ] && identity=$(nmcli --escape no -g 802-1x.identity connection show uuid "$1")
                    exec nmcli --wait 30 connection up uuid "$1" passwd-file <(
                        printf '%s:%s\\n' "$2" "$(passwd_file_value "$PASSWORD")"
                        [ -n "$identity" ] && printf '802-1x.identity:%s\\n' "$(passwd_file_value "$identity")"
                    ) ;;
            esac
            printf 'set %s %s\\nsave persistent\\nquit\\n' "$2" "$PASSWORD" | nmcli connection edit uuid "$1" > /dev/null
            exec nmcli --wait 30 connection up uuid "$1"
        }
    `

    function connectToWifiNetwork(accessPoint: WifiAccessPoint, password = ""): void {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        if (accessPoint.isEnterprise) {
            // `nmcli dev wifi connect` can't create 802.1X profiles, so only bring up an existing one.
            // If there's none, the command fails and we ask for credentials.
            // Wrong 802.1X credentials otherwise keep nmcli waiting for the default 90s.
            // exec so that stopping a superseded attempt stops nmcli itself
            startConnectProc(accessPoint, ["bash", "-c", root.findWifiProfileScript + root.connectWithPasswordScript + `
                SSID="$1"
                uuid=$(find_profile)
                [ -n "$uuid" ] || exit 1
                # Certificate-based (EAP-TLS) profiles have no username/password to ask for
                [ "$(nmcli -g 802-1x.eap connection show uuid "$uuid")" = "tls" ] && echo "eap-tls"
                [ -n "$PASSWORD" ] || exec nmcli --wait 30 connection up uuid "$uuid"
                connect_with_password "$uuid" 802-1x.password
            `, "bash", accessPoint.ssid], password)
            return;
        }
        if (password.length > 0) {
            // Without a profile, `nmcli dev wifi connect` creates one, reading the key from stdin
            startConnectProc(accessPoint, ["bash", "-c", root.findWifiProfileScript + root.connectWithPasswordScript + `
                SSID="$1"
                uuid=$(find_profile)
                [ -n "$uuid" ] || exec nmcli --wait 30 --ask dev wifi connect "$SSID" <<< "$PASSWORD"
                connect_with_password "$uuid" 802-11-wireless-security.psk
            `, "bash", accessPoint.ssid], password)
            return;
        }
        // We use this instead of `nmcli connection up SSID` because this also creates a connection profile
        startConnectProc(accessPoint, ["nmcli", "dev", "wifi", "connect", accessPoint.ssid])

    }

    function startConnectProc(accessPoint: WifiAccessPoint, command: list<string>, password = ""): void {
        // One process per attempt: a killed nmcli exits normally with code 1, so with a shared
        // process the old attempt's exit would be taken as the new one failing
        const previous = root.currentConnectProc;
        root.currentConnectProc = connectProcComp.createObject(root, {
            target: accessPoint,
            command: command,
            password: password
        });
        if (previous) previous.running = false;
        root.currentConnectProc.running = true;
    }

    function disconnectWifiNetwork(): void {
        // By UUID, as the profile name can differ from the SSID
        if (active) disconnectProc.exec({
            "environment": {
                "SSID": active.ssid
            },
            "command": ["bash", "-c", root.findWifiProfileScript + `
                uuid=$(find_profile --active)
                [ -n "$uuid" ] && nmcli connection down uuid "$uuid"
            `]
        });
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = "", domain = ""): void {
        if (!network.isEnterprise) {
            root.connectToWifiNetwork(network, password);
            return;
        }
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        changePasswordProc.network = network;
        changePasswordProc.password = password;
        // Reuse an existing profile (keeping e.g. its CA validation from a provisioning tool), otherwise
        // create one. PEAP and TTLS with MSCHAPv2 cover most networks; the server picks the method.
        // With a domain, the server certificate must chain to a system CA and match it; without one,
        // created profiles don't validate the server. Validation is only changed when the domain differs
        // from the saved one, so clearing it turns the system CA check off and leaving it as is keeps
        // an existing profile's settings.
        // The password itself is set when connecting.
        // Without a username there's nothing to create, so the retry just asks again
        changePasswordProc.exec({
            "environment": {
                "IDENTITY": username,
                "DOMAIN": domain,
                "SAVED_DOMAIN": network.savedDomain,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", root.findWifiProfileScript + `
                args=(802-1x.password-flags 0)
                if [ "$DOMAIN" != "$SAVED_DOMAIN" ]; then
                    if [ -n "$DOMAIN" ]; then
                        args+=(802-1x.system-ca-certs yes 802-1x.domain-suffix-match "$DOMAIN")
                    else
                        args+=(802-1x.system-ca-certs no 802-1x.domain-suffix-match "")
                    fi
                fi
                uuid=$(find_profile)
                if [ -n "$uuid" ]; then
                    [ -n "$IDENTITY" ] && args+=(802-1x.identity "$IDENTITY")
                    nmcli connection modify uuid "$uuid" "\${args[@]}"
                elif [ -n "$IDENTITY" ]; then
                    nmcli connection add type wifi con-name "$SSID" ssid "$SSID" \\
                        wifi-sec.key-mgmt wpa-eap 802-1x.eap peap,ttls 802-1x.phase2-auth mschapv2 \\
                        802-1x.identity "$IDENTITY" "\${args[@]}"
                fi
            `]
        })
    }

    function askForPassword(accessPoint: WifiAccessPoint): void {
        // Show the domain the saved profile validates against, so it can be corrected or cleared
        if (!accessPoint.askingPassword && accessPoint.isEnterprise) {
            accessPoint.savedDomain = "";
            savedDomainProc.target = accessPoint;
            savedDomainProc.exec({
                "environment": {
                    "SSID": accessPoint.ssid
                },
                "command": ["bash", "-c", root.findWifiProfileScript + `
                    uuid=$(find_profile)
                    [ -n "$uuid" ] && nmcli --escape no -g 802-1x.domain-suffix-match connection show uuid "$uuid"
                `]
            })
        }
        accessPoint.askingPassword = true;
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: savedDomainProc
        property WifiAccessPoint target
        stdout: StdioCollector {
            onStreamFinished: {
                if (savedDomainProc.target) savedDomainProc.target.savedDomain = text.trim();
            }
        }
    }

    Component {
        id: connectProcComp

        Process {
            id: connectProc
            required property WifiAccessPoint target
            readonly property bool current: root.currentConnectProc === connectProc
            property bool askForCredentials: true
            property string password
            environment: ({
                LANG: "C",
                LC_ALL: "C",
                PASSWORD: connectProc.password
            })
            stdout: SplitParser {
                onRead: line => {
                    // print(line)
                    if (line === "eap-tls") connectProc.askForCredentials = false
                    getNetworks.running = true
                }
            }
            stderr: SplitParser {
                onRead: line => {
                    // print("err:", line)
                    if (connectProc.current && connectProc.target && connectProc.askForCredentials && line.includes("Secrets were required")) {
                        root.askForPassword(connectProc.target)
                    }
                }
            }
            onExited: (exitCode, exitStatus) => {
                // Superseded attempts must not touch the state of the newer one
                if (connectProc.current) {
                    // The target is gone if a rescan regrouped its SSID under another BSSID meanwhile
                    if (connectProc.target) {
                        if (exitCode !== 0 && connectProc.askForCredentials) root.askForPassword(connectProc.target)
                        else connectProc.target.askingPassword = false
                    }
                    root.wifiConnectTarget = null
                    root.currentConnectProc = null
                }
                connectProc.destroy()
            }
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
        property WifiAccessPoint network
        property string password
        onExited: { // Re-attempt connection after updating the profile, unless another network was picked meanwhile
            if (network && root.wifiConnectTarget === network) root.connectToWifiNetwork(network, password);
            password = "";
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
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
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
