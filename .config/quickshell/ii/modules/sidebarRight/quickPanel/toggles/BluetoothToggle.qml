import qs
import qs.services
import "../"
import Quickshell
import Quickshell.Bluetooth

QuickToggle {
    isSupported: Bluetooth?.defaultAdapter
    toggled: BluetoothStatus.connected
    buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    downAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth?.defaultAdapter?.enabled;
    }
    toggleText: "Bluetooth"
    halfToggled: BluetoothStatus.enabled
    stateText: BluetoothStatus.connected ? BluetoothStatus?.firstActiveDevice.name : halfToggled ? "Not Connected" : ""

}
