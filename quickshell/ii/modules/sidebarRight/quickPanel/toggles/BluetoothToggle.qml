

import qs
import qs.services
import "../"
import "../services/"
import Quickshell
import Quickshell.Bluetooth


QuickToggle  {
    toggled: BluetoothStatus.connected
    buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    downAction: () =>  {

        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    toggleText: "Bluetooth"
    stateText: BluetoothStatus.connected ? BluetoothStatus?.firstActiveDevice.name : "Off"
    halfToggled : BluetoothStatus.enabled

    altAction: () => {
        Bluetooth.defaultAdapter.enabled = true;
        Bluetooth.defaultAdapter.discovering = true;
        DialogContext.showBluetoothDialog = true;
    }

}
