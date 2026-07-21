import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true
    property bool availableNetworksExpanded: true
    property string expandedSavedNetworkUuid: ""
    property var savedNetworks: []
    property var savedNetworkAutoconnectOverrides: ({})

    function parseNmcliLine(line) {
        const placeholder = "ESCAPED_COLON_PLACEHOLDER";
        return line.replace(/\\:/g, placeholder).split(":").map(part => part.replace(new RegExp(placeholder, "g"), ":"));
    }

    function refreshSavedNetworks() {
        savedNetworksProc.running = false;
        savedNetworksProc.running = true;
    }

    function savedNetworkAutoconnectEnabled(network) {
        if (!network)
            return false;
        if (Object.prototype.hasOwnProperty.call(savedNetworkAutoconnectOverrides, network.uuid))
            return savedNetworkAutoconnectOverrides[network.uuid];
        return network.autoconnect === "yes";
    }

    function setSavedNetworkAutoconnect(network, enabled) {
        if (!network)
            return;

        const overrides = Object.assign({}, savedNetworkAutoconnectOverrides);
        overrides[network.uuid] = enabled;
        savedNetworkAutoconnectOverrides = overrides;
        Quickshell.execDetached(["nmcli", "connection", "modify", "uuid", network.uuid, "connection.autoconnect", enabled ? "yes" : "no"]);
        savedNetworksRefreshTimer.restart();
    }

    component SettingsWifiNetworkItem: DialogListItem {
        id: itemRoot
        required property WifiAccessPoint wifiNetwork
        property bool expanded: false

        Layout.fillWidth: true
        enabled: !(Network.wifiConnectTarget === wifiNetwork && !wifiNetwork?.active)
        active: (wifiNetwork?.askingPassword || wifiNetwork?.active) ?? false
        buttonRadius: Appearance.rounding.normal
        onClicked: expanded = !expanded

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
                    iconSize: Appearance.font.pixelSize.larger
                    property int strength: itemRoot.wifiNetwork?.strength ?? 0
                    text: strength > 80 ? "signal_wifi_4_bar" : strength > 60 ? "network_wifi_3_bar" : strength > 40 ? "network_wifi_2_bar" : strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: itemRoot.wifiNetwork?.ssid ?? Translation.tr("Unknown")
                    textFormat: Text.PlainText
                }

                MaterialSymbol {
                    visible: (itemRoot.wifiNetwork?.isSecure || itemRoot.wifiNetwork?.active) ?? false
                    text: itemRoot.wifiNetwork?.active ? "check" : Network.wifiConnectTarget === itemRoot.wifiNetwork ? "settings_ethernet" : "lock"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant
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
                visible: itemRoot.expanded && !(itemRoot.wifiNetwork?.askingPassword ?? false)
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: itemRoot.wifiNetwork?.active
                        ? Translation.tr("Connected")
                        : itemRoot.wifiNetwork?.isSecure
                            ? Translation.tr("Secured network")
                            : Translation.tr("Open network")
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                DialogButton {
                    buttonText: itemRoot.wifiNetwork?.active ? Translation.tr("Disconnect") : Translation.tr("Connect")
                    onClicked: {
                        if (itemRoot.wifiNetwork?.active)
                            Network.disconnectWifiNetwork();
                        else
                            Network.connectToWifiNetwork(itemRoot.wifiNetwork);
                    }
                }
            }

            ColumnLayout {
                Layout.topMargin: 2
                visible: itemRoot.wifiNetwork?.askingPassword ?? false

                MaterialTextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Password")
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    onAccepted: Network.changePassword(itemRoot.wifiNetwork, passwordField.text)
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    DialogButton {
                        buttonText: Translation.tr("Cancel")
                        onClicked: itemRoot.wifiNetwork.askingPassword = false
                    }

                    DialogButton {
                        buttonText: Translation.tr("Connect")
                        onClicked: Network.changePassword(itemRoot.wifiNetwork, passwordField.text)
                    }
                }
            }
        }
    }

    component SavedNetworkItem: Rectangle {
        id: itemRoot
        required property var network
        property bool expanded: root.expandedSavedNetworkUuid === network.uuid
        property bool active: network.name === Network.networkName

        Layout.fillWidth: true
        implicitHeight: savedNetworkContent.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: itemRoot.active ? Appearance.colors.colLayer3 : savedNetworkMouseArea.containsMouse ? Appearance.colors.colLayer3Hover : "transparent"
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: savedNetworkContent
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: savedNetworkHeader.implicitHeight

                    MouseArea {
                        id: savedNetworkMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.expandedSavedNetworkUuid = itemRoot.expanded ? "" : itemRoot.network.uuid
                    }

                    RowLayout {
                        id: savedNetworkHeader
                        anchors.fill: parent
                        spacing: 10

                        MaterialSymbol {
                            text: itemRoot.active ? "check" : "bookmark"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: itemRoot.network.name
                                color: Appearance.colors.colOnSurfaceVariant
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.savedNetworkAutoconnectEnabled(itemRoot.network) ? Translation.tr("Connects automatically") : Translation.tr("Manual connection")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                elide: Text.ElideRight
                            }
                        }

                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Connect")
                    enabled: !itemRoot.active
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "connection", "up", "uuid", itemRoot.network.uuid]);
                        savedNetworksRefreshTimer.restart();
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Forget")
                    colText: Appearance.colors.colError
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", itemRoot.network.uuid]);
                        savedNetworksRefreshTimer.restart();
                    }
                }

                Item {
                    implicitWidth: savedNetworkArrow.implicitWidth
                    implicitHeight: savedNetworkArrow.implicitHeight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expandedSavedNetworkUuid = itemRoot.expanded ? "" : itemRoot.network.uuid
                    }

                    MaterialSymbol {
                        id: savedNetworkArrow
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
            }

            RowLayout {
                visible: itemRoot.expanded
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "settings_backup_restore"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    opacity: 0
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Connect automatically")
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledSwitch {
                    Layout.fillWidth: false
                    checked: root.savedNetworkAutoconnectEnabled(itemRoot.network)
                    onClicked: root.setSavedNetworkAutoconnect(itemRoot.network, !root.savedNetworkAutoconnectEnabled(itemRoot.network))
                }
            }
        }
    }

    Component.onCompleted: {
        Network.update();
        Network.rescanWifi();
        root.refreshSavedNetworks();
    }

    Timer {
        id: savedNetworksRefreshTimer
        interval: 800
        repeat: false
        onTriggered: root.refreshSavedNetworks()
    }

    Process {
        id: savedNetworksProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT", "connection", "show"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = text.trim().split("\n").filter(line => line.length > 0).map(line => {
                    const fields = root.parseNmcliLine(line);
                    return {
                        name: fields[0] ?? "",
                        uuid: fields[1] ?? "",
                        type: fields[2] ?? "",
                        autoconnect: fields[3] ?? ""
                    };
                }).filter(network => network.type === "802-11-wireless" || network.type === "wifi");
                root.savedNetworkAutoconnectOverrides = ({});
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            OptionalMaterialSymbol {
                icon: Network.materialSymbol
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Networks")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnSecondaryContainer
            }

            DialogButton {
                buttonText: Translation.tr("Advanced settings")
                onClicked: Quickshell.execDetached(["bash", "-c", "systemsettings kcm_networkmanagement || plasmawindowed kcm_networkmanagement"])
            }
        }

        ConfigSwitch {
            buttonIcon: Network.wifiEnabled ? "wifi" : "signal_wifi_off"
            text: Network.wifiEnabled ? Translation.tr("Wi-Fi enabled") : Translation.tr("Wi-Fi disabled")
            checked: Network.wifiEnabled
            onCheckedChanged: {
                Network.enableWifi(checked);
                if (checked)
                    Network.rescanWifi();
            }
        }

        ConfigRow {
            visible: Network.wifiEnabled

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                text: Network.wifiStatus === "connected"
                    ? Translation.tr("Connected to %1").arg(Network.networkName || Network.active?.ssid || Translation.tr("Unknown"))
                    : Network.wifiStatus === "disabled"
                        ? Translation.tr("Wireless radio is off")
                        : Translation.tr("Not connected")
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            DialogButton {
                visible: Network.active !== null
                buttonText: Translation.tr("Disconnect")
                onClicked: Network.disconnectWifiNetwork()
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: availableHeaderContent.implicitHeight + 8
            onClicked: root.availableNetworksExpanded = !root.availableNetworksExpanded

            contentItem: RowLayout {
                id: availableHeaderContent
                spacing: 6

                OptionalMaterialSymbol {
                    icon: "travel_explore"
                    iconSize: Appearance.font.pixelSize.hugeass
                }

                StyledText {
                    text: Translation.tr("Available networks")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }

                MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: root.availableNetworksExpanded ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        ConfigRow {
            DialogButton {
                buttonText: Network.wifiScanning ? Translation.tr("Scanning") : Translation.tr("Scan")
                enabled: Network.wifiEnabled && !Network.wifiScanning
                onClicked: Network.rescanWifi()
            }

            StyledText {
                Layout.fillWidth: true
                text: Network.wifiScanning
                    ? Translation.tr("Scanning for networks...")
                    : Network.friendlyWifiNetworks.length === 1
                        ? Translation.tr("1 network found")
                        : Translation.tr("%1 networks found").arg(Network.friendlyWifiNetworks.length)
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.availableNetworksExpanded && !Network.wifiEnabled
            text: Translation.tr("Turn on Wi-Fi to scan for networks.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.availableNetworksExpanded && Network.wifiEnabled && !Network.wifiScanning && Network.friendlyWifiNetworks.length === 0
            text: Translation.tr("No networks found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: ScriptModel {
                values: root.availableNetworksExpanded ? Network.friendlyWifiNetworks : []
            }

            SettingsWifiNetworkItem {
                required property WifiAccessPoint modelData
                wifiNetwork: modelData
            }
        }
    }

    ContentSection {
        icon: "bookmark"
        title: Translation.tr("Saved networks")

        ConfigRow {
            DialogButton {
                buttonText: Translation.tr("Refresh")
                onClicked: root.refreshSavedNetworks()
            }

            StyledText {
                Layout.fillWidth: true
                text: root.savedNetworks.length === 1
                    ? Translation.tr("1 saved Wi-Fi profile")
                    : Translation.tr("%1 saved Wi-Fi profiles").arg(root.savedNetworks.length)
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.savedNetworks.length === 0
            text: Translation.tr("No saved Wi-Fi networks found.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.savedNetworks

            SavedNetworkItem {
                required property var modelData
                Layout.fillWidth: true
                network: modelData
            }
        }
    }
}
