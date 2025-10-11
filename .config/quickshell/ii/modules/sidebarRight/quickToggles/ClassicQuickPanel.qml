import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

import "./classicStyle"

ButtonGroup {

    property real heightSize: 50

    spacing: 5
    padding: 5
    color: Appearance.colors.colLayer1
    
    NetworkToggle {
        altAction: () => {
            Network.enableWifi();
            Network.rescanWifi();
            root.showWifiDialog = true;
        }
    }
    BluetoothToggle {
        altAction: () => {
            Bluetooth.defaultAdapter.enabled = true;
            Bluetooth.defaultAdapter.discovering = true;
            root.showBluetoothDialog = true;
        }
    }
    NightLight {}
    GameMode {}
    IdleInhibitor {}
    EasyEffectsToggle {}
    CloudflareWarp {}
}