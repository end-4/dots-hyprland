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

    property var savedNetworks: []

    function parseNmcliLine(line) {
        const placeholder = "ESCAPED_COLON_PLACEHOLDER";
        return line.replace(/\\:/g, placeholder).split(":").map(part => part.replace(new RegExp(placeholder, "g"), ":"));
    }

    function refresh() {
        savedNetworksProc.running = false;
        savedNetworksProc.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer
        interval: 800
        repeat: false
        onTriggered: root.refresh()
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
            }
        }
    }

    component SavedNetworkItem: DialogListItem {
        id: itemRoot
        required property var network
        active: network.name === Network.networkName
        verticalPadding: 8
        buttonRadius: Appearance.rounding.normal

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
                    text: itemRoot.network.autoconnect === "yes" ? Translation.tr("Connects automatically") : Translation.tr("Manual connection")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    elide: Text.ElideRight
                }
            }

            DialogButton {
                buttonText: Translation.tr("Connect")
                enabled: !itemRoot.active
                onClicked: {
                    Quickshell.execDetached(["nmcli", "connection", "up", "uuid", itemRoot.network.uuid]);
                    refreshTimer.restart();
                }
            }

            DialogButton {
                buttonText: Translation.tr("Forget")
                colText: Appearance.colors.colError
                onClicked: {
                    Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", itemRoot.network.uuid]);
                    refreshTimer.restart();
                }
            }
        }
    }

    ContentSection {
        icon: "bookmark"
        title: Translation.tr("Saved networks")

        ConfigRow {
            DialogButton {
                buttonText: Translation.tr("Refresh")
                onClicked: root.refresh()
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
