import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    WindowDialogTitle {
        text: Translation.tr("Connect to Wi-Fi")
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
                const settingsPath = CF.FileUtils.trimFileProtocol(Directories.config) + "/quickshell/ii/settings.qml";
                Quickshell.execDetached(["sh", "-c", "QS_SETTINGS_PAGE=1 QS_SETTINGS_TAB=0 quickshell -p '" + settingsPath + "'"]);
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