import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        WindowDialogTitle {
            Layout.fillWidth: true
            text: Translation.tr("Connect to Wi-Fi")
        }

        DialogButton {
            id: rescanButton
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 36
            implicitHeight: 36
            buttonText: ""

            enabled: !Network.wifiScanning
            opacity: Network.wifiScanning ? 0.4 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            onClicked: Network.rescanWifi()

            contentItem: Item {
                anchors.fill: parent

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "restart_alt"
                    iconSize: 20
                    color: rescanButton.enabled ? rescanButton.colEnabled : rescanButton.colDisabled
                }
            }
        }
    }
    WindowDialogSeparator {
        visible: !Network.wifiScanning
    }
    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }
    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0

        model: ScriptModel {
            values: Network.friendlyWifiNetworks
        }
        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData
            wifiNetwork: modelData
            width: ListView.view.width
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
