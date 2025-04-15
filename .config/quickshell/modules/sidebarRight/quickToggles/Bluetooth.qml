import "../"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import Quickshell
import Quickshell.Io

QuickToggleButton {
    toggled: Bluetooth.bluetoothEnabled
    buttonIcon: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: {
            if (mouse.button === Qt.LeftButton) {
                toggleBluetooth.running = true
            }
            if (mouse.button === Qt.RightButton) {
                configureBluetooth.running = true
            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
    }
    Process {
        id: configureBluetooth
        command: ["bash", "-c", `${ConfigOptions.apps.bluetooth} & qs ipc call sidebarRight close`]
    }
    Process {
        id: toggleBluetooth
        command: ["bash", "-c", `bluetoothctl power ${Bluetooth.bluetoothEnabled ? "off" : "on"}`]
        onRunningChanged: {
            if(!running) {
                Bluetooth.update()
            }
        }
    }
    StyledToolTip {
        content: `${(Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? 
            Bluetooth.bluetoothDeviceName : "Bluetooth"} | Right-click to configure`

    }
}
