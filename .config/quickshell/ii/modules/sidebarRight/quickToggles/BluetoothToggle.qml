import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice bluetoothDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property bool bluetoothConnected: bluetoothDevice !== undefined
    toggled: bluetoothEnabled
    buttonIcon: bluetoothConnected ? "bluetooth_connected" : bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
    onClicked: {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`])
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        content: Translation.tr("%1 | Right-click to configure").arg(
            (bluetoothDevice?.name.length > 0) ?
            bluetoothDevice.name : Translation.tr("Bluetooth"))
    }
}
