import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Bluetooth settings — wraps the existing BluetoothStatus service
 * and provides a launcher to the KDE Bluetooth KCM.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "bluetooth"
        title: Translation.tr("Bluetooth")

        StyledText {
            text: BluetoothStatus.enabled ? Translation.tr("Bluetooth is on") : Translation.tr("Bluetooth is off")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer0
        }

        ConfigSwitch {
            buttonIcon: "bluetooth"
            text: Translation.tr("Enable Bluetooth")
            checked: BluetoothStatus.enabled
            onCheckedChanged: {
                Quickshell.execDetached(["bluetoothctl", "power", checked ? "on" : "off"])
            }
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "settings_bluetooth"
            mainText: Translation.tr("Open Bluetooth manager")
            buttonRadius: Appearance.rounding.small
            onClicked: Quickshell.execDetached(["bash", "-c", Config.options.apps.bluetooth])
        }
    }
}
