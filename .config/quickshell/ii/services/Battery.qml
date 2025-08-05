pragma Singleton

import qs
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Io

Singleton {
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice.percentage
    readonly property bool allowAutomaticSuspend: Config.options.battery.automaticSuspend

    property bool isLow: percentage <= Config.options.battery.low / 100
    property bool isCritical: percentage <= Config.options.battery.critical / 100
    property bool isSuspending: percentage <= Config.options.battery.suspend / 100

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull
    property real temperature: 0

    Process {
        id: tempProcess
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    Battery.temperature = parseInt(text.trim()) / 1000
                } else {
                    Battery.temperature = 0
                }
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (!tempProcess.running) {
                tempProcess.running = true
            }
        }
    }

    Component.onCompleted: {
        if (!tempProcess.running) {
            tempProcess.running = true;
        }
    }


    onIsLowAndNotChargingChanged: {
        if (available && isLowAndNotCharging) Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Low battery"), 
            Translation.tr("Consider plugging in your device"), 
            "-u", "critical",
            "-a", "Shell"
        ])
    }

    onIsCriticalAndNotChargingChanged: {
        if (available && isCriticalAndNotCharging) Quickshell.execDetached([
            "notify-send", 
            Translation.tr("Critically low battery"), 
            Translation.tr("Please charge!\nAutomatic suspend triggers at %1").arg(Config.options.battery.suspend), 
            "-u", "critical",
            "-a", "Shell"
        ]);
            
    }

    onIsSuspendingAndNotChargingChanged: {
        if (available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }
}
