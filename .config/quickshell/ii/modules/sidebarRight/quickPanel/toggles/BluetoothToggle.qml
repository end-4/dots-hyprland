import qs
import qs.services
import "../"
import "../../bluetoothDevices/"
import Quickshell
import Quickshell.Bluetooth

QuickToggle {
    isSupported: Bluetooth?.defaultAdapter
    toggled: BluetoothStatus.connected
    buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    downAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled;
    }
    toggleText: "Bluetooth"
    stateText: BluetoothStatus.connected ? BluetoothStatus?.firstActiveDevice.name : "Off"
    halfToggled: BluetoothStatus.enabled

    altAction: () => {
        Bluetooth.defaultAdapter.enabled = true;
        Bluetooth.defaultAdapter.discovering = true;
        BluetoothDialogContext.showBluetoothDialog = true;
    }
}
