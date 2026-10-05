import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property var vpnConnections: []
    property var activeVpnConnections: []
    property var activeWireguardInterfaces: []
    property var localConfigs: []
    property bool localConfigsExpanded: false
    property bool normalizingAutoconnect: false
    property var autoconnectOverrides: ({})
    property string expandedVpnUuid: ""
    property string lastVpnUuid: ""
    readonly property bool vpnActive: activeVpnConnections.length > 0 || activeWireguardInterfaces.length > 0

    function parseNmcliLine(line) {
        const placeholder = "ESCAPED_COLON_PLACEHOLDER";
        return line.replace(/\\:/g, placeholder).split(":").map(part => part.replace(new RegExp(placeholder, "g"), ":"));
    }

    function refresh() {
        vpnConnectionsProc.running = false;
        activeVpnConnectionsProc.running = false;
        activeWireguardInterfacesProc.running = false;
        localConfigsProc.running = false;
        vpnConnectionsProc.running = true;
        activeVpnConnectionsProc.running = true;
        activeWireguardInterfacesProc.running = true;
        localConfigsProc.running = true;
    }

    function refreshStatus() {
        activeVpnConnectionsProc.running = false;
        activeWireguardInterfacesProc.running = false;
        activeVpnConnectionsProc.running = true;
        activeWireguardInterfacesProc.running = true;
    }

    function isActive(uuid) {
        return activeVpnConnections.some(vpn => vpn.uuid === uuid);
    }

    function isVpnActive(vpn) {
        if (!vpn)
            return false;
        return root.isActive(vpn.uuid) || activeWireguardInterfaces.includes(vpn.name);
    }

    function unmanagedWireguardInterfaces() {
        return activeWireguardInterfaces.filter(interfaceName => !root.isNetworkManagerWireguardInterface(interfaceName));
    }

    function firstInactiveVpn() {
        return vpnConnections.find(vpn => !root.isVpnActive(vpn)) ?? null;
    }

    function preferredVpn() {
        const lastVpn = vpnConnections.find(vpn => vpn.uuid === lastVpnUuid);
        if (lastVpn)
            return lastVpn;
        const autoconnectVpn = vpnConnections.find(vpn => root.vpnAutoconnectEnabled(vpn));
        if (autoconnectVpn)
            return autoconnectVpn;
        return root.firstInactiveVpn();
    }

    function syncLastVpnFromState() {
        for (const vpn of vpnConnections) {
            if (root.isVpnActive(vpn)) {
                lastVpnUuid = vpn.uuid;
                return;
            }
        }
    }

    function activeVpnNames() {
        const names = [];
        for (const vpn of activeVpnConnections) {
            if (!names.includes(vpn.name))
                names.push(vpn.name);
        }
        for (const interfaceName of activeWireguardInterfaces) {
            if (!names.includes(interfaceName))
                names.push(interfaceName);
        }
        return names;
    }

    function connectVpn(vpn) {
        if (!vpn)
            return;
        lastVpnUuid = vpn.uuid;
        connectVpnProc.command = [
            "bash",
            "-c",
            "target_uuid=\"$1\"; shift; while [ \"$1\" != \"--\" ]; do nmcli connection down uuid \"$1\" >/dev/null 2>&1 || true; shift; done; shift; for iface in \"$@\"; do pkexec wg-quick down \"$iface\" >/dev/null 2>&1 || true; done; nmcli connection up uuid \"$target_uuid\"",
            "vpn-connect",
            vpn.uuid,
            ...activeVpnConnections.map(activeVpn => activeVpn.uuid),
            "--",
            ...root.unmanagedWireguardInterfaces()
        ];
        connectVpnProc.running = false;
        connectVpnProc.running = true;
        refreshTimer.restart();
    }

    function disconnectVpn(vpn) {
        if (!vpn)
            return;
        if (root.isActive(vpn.uuid))
            Quickshell.execDetached(["nmcli", "connection", "down", "uuid", vpn.uuid]);
        if (activeWireguardInterfaces.includes(vpn.name) && !root.isNetworkManagerWireguardInterface(vpn.name))
            root.disconnectWireguardInterface(vpn.name);
        refreshTimer.restart();
    }

    function isNetworkManagerWireguardInterface(interfaceName) {
        return activeVpnConnections.some(vpn => vpn.name === interfaceName || vpn.device === interfaceName);
    }

    function disconnectWireguardInterface(interfaceName) {
        if (!interfaceName)
            return;
        Quickshell.execDetached(["pkexec", "wg-quick", "down", interfaceName]);
        refreshTimer.restart();
    }

    function disconnectAllVpns() {
        for (const vpn of activeVpnConnections)
            Quickshell.execDetached(["nmcli", "connection", "down", "uuid", vpn.uuid]);
        for (const interfaceName of activeWireguardInterfaces) {
            if (!root.isNetworkManagerWireguardInterface(interfaceName))
                root.disconnectWireguardInterface(interfaceName);
        }
        refreshTimer.restart();
    }

    function importConfig(path) {
        if (!path)
            return;
        importVpnProc.command = ["bash", "-c", "output=$(LC_ALL=C nmcli connection import type wireguard file \"$1\"); uuid=$(printf '%s\\n' \"$output\" | sed -n \"s/^Connection '.*' (\\(.*\\)) successfully added\\.$/\\1/p\"); [ -n \"$uuid\" ] && nmcli connection modify uuid \"$uuid\" connection.autoconnect no", "vpn-import", path];
        importVpnProc.running = false;
        importVpnProc.running = true;
    }

    function autoconnectVpns() {
        return vpnConnections.filter(vpn => vpn.autoconnect === "yes");
    }

    function setAutoconnect(vpn, enabled) {
        if (!vpn)
            return;

        const overrides = {};
        overrides[vpn.uuid] = enabled;
        autoconnectOverrides = overrides;

        if (enabled) {
            for (const candidate of vpnConnections)
                Quickshell.execDetached(["nmcli", "connection", "modify", "uuid", candidate.uuid, "connection.autoconnect", candidate.uuid === vpn.uuid ? "yes" : "no"]);
        } else {
            Quickshell.execDetached(["nmcli", "connection", "modify", "uuid", vpn.uuid, "connection.autoconnect", "no"]);
        }

        refreshTimer.restart();
    }

    function vpnAutoconnectEnabled(vpn) {
        if (!vpn)
            return false;
        if (Object.prototype.hasOwnProperty.call(autoconnectOverrides, vpn.uuid))
            return autoconnectOverrides[vpn.uuid];
        return vpn.autoconnect === "yes";
    }

    function normalizeAutoconnect() {
        const enabledVpns = root.autoconnectVpns();
        if (enabledVpns.length <= 1 || normalizingAutoconnect)
            return;

        normalizingAutoconnect = true;
        const activeAutoconnectVpn = enabledVpns.find(vpn => root.isVpnActive(vpn));
        const keepVpn = activeAutoconnectVpn ?? enabledVpns[0];

        for (const vpn of enabledVpns) {
            if (vpn.uuid !== keepVpn.uuid)
                Quickshell.execDetached(["nmcli", "connection", "modify", "uuid", vpn.uuid, "connection.autoconnect", "no"]);
        }

        normalizeAutoconnectTimer.restart();
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer
        interval: 900
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    Timer {
        id: normalizeAutoconnectTimer
        interval: 900
        repeat: false
        onTriggered: {
            root.normalizingAutoconnect = false;
            root.refresh();
        }
    }

    Process {
        id: vpnConnectionsProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT", "connection", "show"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.vpnConnections = text.trim().split("\n").filter(line => line.length > 0).map(line => {
                    const fields = root.parseNmcliLine(line);
                    return {
                        name: fields[0] ?? "",
                        uuid: fields[1] ?? "",
                        type: fields[2] ?? "",
                        autoconnect: fields[3] ?? ""
                    };
                }).filter(vpn => vpn.type === "wireguard").sort((a, b) => a.name.localeCompare(b.name));
                root.autoconnectOverrides = ({});
                root.normalizeAutoconnect();
            }
        }
    }

    Process {
        id: activeVpnConnectionsProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show", "--active"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeVpnConnections = text.trim().split("\n").filter(line => line.length > 0).map(line => {
                    const fields = root.parseNmcliLine(line);
                    return {
                        name: fields[0] ?? "",
                        uuid: fields[1] ?? "",
                        type: fields[2] ?? "",
                        device: fields[3] ?? ""
                    };
                }).filter(vpn => vpn.type === "wireguard").sort((a, b) => a.name.localeCompare(b.name));
                root.syncLastVpnFromState();
            }
        }
    }

    Process {
        id: activeWireguardInterfacesProc
        command: ["sh", "-c", "command -v wg >/dev/null 2>&1 && wg show interfaces 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeWireguardInterfaces = text.trim().split(/[ \n\t]+/).filter(interfaceName => interfaceName.length > 0);
                root.syncLastVpnFromState();
            }
        }
    }

    Process {
        id: importVpnProc
        onExited: refreshTimer.restart()
    }

    Process {
        id: connectVpnProc
        onExited: refreshTimer.restart()
    }

    Process {
        id: localConfigsProc
        command: ["bash", "-c", "mkdir -p \"$HOME/Documents/VPN\"; find \"$HOME/Documents/VPN\" -maxdepth 1 -type f -name '*.conf' -printf '%f\\t%p\\n' | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.localConfigs = text.trim().split("\n").filter(line => line.length > 0).map(line => {
                    const fields = line.split("\t");
                    const fileName = fields[0] ?? "";
                    const path = fields.slice(1).join("\t");
                    return {
                        name: fileName.replace(/\\.conf$/, ""),
                        fileName,
                        path
                    };
                });
            }
        }
    }

    Process {
        id: importVpnFromPickerProc
        command: ["bash", "-c", "mkdir -p \"$HOME/Documents/VPN\"; file=$(zenity --file-selection --filename=\"$HOME/Documents/VPN/\" --file-filter='WireGuard config (*.conf) | *.conf' 2>/dev/null); [ -n \"$file\" ] || exit 0; output=$(LC_ALL=C nmcli connection import type wireguard file \"$file\"); uuid=$(printf '%s\\n' \"$output\" | sed -n \"s/^Connection '.*' (\\(.*\\)) successfully added\\.$/\\1/p\"); [ -n \"$uuid\" ] && nmcli connection modify uuid \"$uuid\" connection.autoconnect no"]
        onExited: refreshTimer.restart()
    }

    component VpnConnectionItem: DialogListItem {
        id: itemRoot
        required property var vpn
        readonly property bool active: root.isVpnActive(vpn)
        readonly property bool expanded: root.expandedVpnUuid === vpn.uuid

        Layout.fillWidth: true
        verticalPadding: 8
        buttonRadius: Appearance.rounding.normal
        pointingHandCursor: true
        onClicked: root.expandedVpnUuid = itemRoot.expanded ? "" : itemRoot.vpn.uuid

        contentItem: ColumnLayout {
            anchors {
                fill: parent
                topMargin: itemRoot.verticalPadding
                bottomMargin: itemRoot.verticalPadding
                leftMargin: itemRoot.horizontalPadding
                rightMargin: itemRoot.horizontalPadding
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: itemRoot.active ? "verified_user" : "vpn_key"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: itemRoot.vpn.name
                        color: Appearance.colors.colOnSurfaceVariant
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: itemRoot.active
                            ? Translation.tr("Connected")
                            : root.vpnAutoconnectEnabled(itemRoot.vpn)
                                ? Translation.tr("Connects automatically")
                                : Translation.tr("Manual connection")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        elide: Text.ElideRight
                    }
                }

                DialogButton {
                    buttonText: itemRoot.active ? Translation.tr("Disconnect") : Translation.tr("Connect")
                    onClicked: {
                        if (itemRoot.active)
                            root.disconnectVpn(itemRoot.vpn);
                        else
                            root.connectVpn(itemRoot.vpn);
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Forget")
                    colText: Appearance.colors.colError
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", itemRoot.vpn.uuid]);
                        refreshTimer.restart();
                    }
                }

                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: itemRoot.expanded ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            RowLayout {
                visible: itemRoot.expanded
                Layout.fillWidth: true
                spacing: 10

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Connect automatically")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledSwitch {
                    id: autoconnectSwitch
                    Layout.fillWidth: false
                    checked: root.vpnAutoconnectEnabled(itemRoot.vpn)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.setAutoconnect(itemRoot.vpn, !root.vpnAutoconnectEnabled(itemRoot.vpn));
                        }
                    }
                }
            }
        }
    }

    component LocalConfigItem: DialogListItem {
        id: itemRoot
        required property var config

        Layout.fillWidth: true
        verticalPadding: 8
        buttonRadius: Appearance.rounding.normal
        pointingHandCursor: false

        contentItem: RowLayout {
            anchors {
                fill: parent
                topMargin: itemRoot.verticalPadding
                bottomMargin: itemRoot.verticalPadding
                leftMargin: itemRoot.horizontalPadding
                rightMargin: itemRoot.horizontalPadding
            }
            spacing: 10

            MaterialSymbol {
                text: "description"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: itemRoot.config.name
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                StyledText {
                    Layout.fillWidth: true
                    text: itemRoot.config.path
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    elide: Text.ElideMiddle
                    textFormat: Text.PlainText
                }
            }

            DialogButton {
                buttonText: Translation.tr("Import")
                enabled: !importVpnProc.running && !importVpnFromPickerProc.running
                onClicked: root.importConfig(itemRoot.config.path)
            }
        }
    }

    ContentSection {
        icon: root.vpnActive ? "enhanced_encryption" : "vpn_key"
        title: Translation.tr("VPN")

        RippleButton {
            id: vpnToggle
            Layout.fillWidth: true
            implicitHeight: contentItem.implicitHeight + 16
            enabled: root.vpnConnections.length > 0 || root.vpnActive
            onClicked: {
                if (root.vpnActive) {
                    root.disconnectAllVpns();
                } else {
                    root.connectVpn(root.preferredVpn());
                }
            }

            contentItem: RowLayout {
                spacing: 10

                OptionalMaterialSymbol {
                    icon: root.vpnActive ? "enhanced_encryption" : "vpn_key_off"
                    opacity: vpnToggle.enabled ? 1 : 0.4
                    iconSize: Appearance.font.pixelSize.larger
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.vpnActive
                        ? Translation.tr("VPN enabled")
                        : Translation.tr("VPN disabled")
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: vpnToggle.enabled ? 1 : 0.4
                }

                StyledSwitch {
                    Layout.fillWidth: false
                    checked: root.vpnActive
                    enabled: false
                    opacity: 1
                }
            }
        }

        ConfigRow {
            DialogButton {
                buttonText: Translation.tr("Refresh")
                onClicked: root.refresh()
            }

            StyledText {
                text: {
                    const names = root.activeVpnNames();
                    return names.length > 0
                        ? `${Translation.tr("Active")}: ${names.join(", ")}`
                        : "";
                }
                visible: text.length > 0
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Item {
                Layout.fillWidth: true
            }

            DialogButton {
                buttonText: Translation.tr("Add VPN")
                enabled: !importVpnProc.running && !importVpnFromPickerProc.running
                onClicked: {
                    importVpnFromPickerProc.running = false;
                    importVpnFromPickerProc.running = true;
                }
            }
        }
    }

    ContentSection {
        icon: "folder"
        title: Translation.tr("Local configs")

        ConfigRow {
            DialogButton {
                buttonText: root.localConfigsExpanded ? Translation.tr("Hide") : Translation.tr("Show")
                onClicked: root.localConfigsExpanded = !root.localConfigsExpanded
            }

            StyledText {
                Layout.fillWidth: true
                text: root.localConfigs.length === 1
                    ? Translation.tr("1 local .conf in ~/Documents/VPN")
                    : Translation.tr("%1 local .conf files in ~/Documents/VPN").arg(root.localConfigs.length)
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.localConfigsExpanded
            text: Translation.tr("Drop WireGuard .conf files in ~/Documents/VPN, then import them from here.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.localConfigsExpanded && root.localConfigs.length === 0
            text: Translation.tr("No local WireGuard configs found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.localConfigsExpanded ? root.localConfigs : []

            LocalConfigItem {
                required property var modelData
                config: modelData
            }
        }
    }

    ContentSection {
        icon: "list"
        title: Translation.tr("Configured VPNs")

        StyledText {
            Layout.fillWidth: true
            visible: root.vpnConnections.length === 0
            text: Translation.tr("No WireGuard VPN profiles found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.vpnConnections

            VpnConnectionItem {
                required property var modelData
                vpn: modelData
            }
        }
    }
}
