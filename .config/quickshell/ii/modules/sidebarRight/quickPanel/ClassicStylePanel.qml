import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import "./"
import "./toggles"

import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ButtonGroup {
    id: toggleParent
    clip: true
    Layout.alignment: Qt.AlignHCenter
    spacing: 5
    padding: 5
    color: Appearance.colors.colLayer1

    property bool showWifiDialog: false // This internal property will be bound to sidebarRightContent
    property bool showBluetoothDialog: false // This internal property will be bound to sidebarRightContent

    property bool configReady: Config.ready

    NetworkToggle {
        toggleType: 0
        // parity
        toolTipText: "" + (toggled ? stateText : toggleText) + " | Right-click to configure"
        altAction: () => {
            Network.enableWifi();
            Network.rescanWifi();
            root.showWifiDialog = true;
        }
    }

    BluetoothToggle {
        toggleType: 0
        toolTipText: Translation.tr("%1 | Right-click to configure").arg((BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth")) + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : ""))

        altAction: () => {
            root.showBluetoothDialog = true;
            Bluetooth.defaultAdapter.enabled = true;
            Bluetooth.defaultAdapter.discovering = true;
        }
    }

    NightLightToggle {
        toolTipText: Translation.tr("Night Light | Right-click to toggle Auto mode")
        toggleType: 0
    }

    GameModeToggle {
        toolTipText: Translation.tr("Game mode")
        toggleType: 0
    }

    IdleInhibitorToggle {
        toolTipText: Translation.tr("Keep system awake")
        toggleType: 0
    }

    EasyEffectsToggle {
        toolTipText: Translation.tr("EasyEffects | Right-click to configure")
        toggleType: 0
    }

    CloudflareWarpToggle {
        toolTipText: Translation.tr("Cloudflare WARP (1.1.1.1)")
        toggleType: 0
    }
}
