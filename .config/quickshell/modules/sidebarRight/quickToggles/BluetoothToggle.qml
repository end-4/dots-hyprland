import "../"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
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
        content: StringUtils.format(qsTr("{0} | Right-click to configure"), 
            (Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? 
            Bluetooth.bluetoothDeviceName : qsTr("Bluetooth"))

    }
}
