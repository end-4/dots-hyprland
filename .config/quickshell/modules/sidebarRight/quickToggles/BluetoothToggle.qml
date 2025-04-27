import "../"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: Bluetooth.bluetoothEnabled
    buttonIcon: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                toggleBluetooth.running = true
            }
            if (mouse.button === Qt.RightButton) {
                Hyprland.dispatch(`exec ${ConfigOptions.apps.bluetooth}`)
                Hyprland.dispatch("global quickshell:sidebarRightClose")

            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor 
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
            Bluetooth.bluetoothDeviceName : "Bluetooth"} | ${qsTr("Right-click to configure")}`

    }
}
