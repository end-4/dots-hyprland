pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * Simple hyprsunset service with automatic mode.
 * In theory we don't need this because hyprsunset has a config file, but it somehow doesn't work.
 * It should also be possible to control it via hyprctl, but it doesn't work consistently either so we're just killing and launching.
 */
Singleton {
    id: root
    property var manualActive
    property string from: Config.options?.light?.night?.from ?? "19:00" // Default to 7 PM
    property string to: Config.options?.light?.night?.to ?? "06:30" // Default to 6:30 AM
    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000 // Default color temperature
    property bool shouldBeOn
    property bool firstEvaluation: true
    property bool active: false

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes


    function isNoLater(hour1, minute1, hour2, minute2) {
        if (hour1 < hour2)
            return true;
        if (hour1 === hour2 && minute1 < minute2)
            return true;
        return false;
    }


    onClockMinuteChanged: reEvaluate()
    onAutomaticChanged: {
        root.manualActive = undefined;
        root.firstEvaluation = true;
        reEvaluate();
    }
    function reEvaluate() {
        const toHourIsNextDay = !isNoLater(fromHour, fromMinute, toHour, toMinute);
        const toHourWrapped = toHourIsNextDay ? toHour + 24 : toHour;
        const toMinuteWrapped = toMinute;
        root.shouldBeOn = isNoLater(fromHour, fromMinute, clockHour, clockMinute) && isNoLater(clockHour, clockMinute, toHourWrapped, toMinuteWrapped);
        if (firstEvaluation) {
            firstEvaluation = false;
            root.ensureState();
        }
    }

    onShouldBeOnChanged: ensureState()
    function ensureState() {
        // console.log("[Hyprsunset] Ensuring state:", root.shouldBeOn, "Automatic mode:", root.automatic);
        if (!root.automatic || root.manualActive !== undefined)
            return;
        if (root.shouldBeOn) {
            root.enable();
        } else {
            root.disable();
        }
    }

    function load() { } // Dummy to force init

    function enable() {
        root.active = true;
        // console.log("[Hyprsunset] Enabling");
        Quickshell.execDetached(["bash", "-c", `pidof hyprsunset || hyprsunset --temperature ${root.colorTemperature}`]);
    }

    function disable() {
        root.active = false;
        // console.log("[Hyprsunset] Disabling");
        Quickshell.execDetached(["bash", "-c", `pkill hyprsunset`]);
    }

    function fetchState() {
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: true
        command: ["bash", "-c", "hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                if (output.length == 0 || output.startsWith("Couldn't"))
                    root.active = false;
                else
                    root.active = (output != "6500");
                // console.log("[Hyprsunset] Fetched state:", output, "->", root.active);
            }
        }
    }

    function toggle() {
        if (root.manualActive === undefined)
            root.manualActive = root.active;

        root.manualActive = !root.manualActive;
        if (root.manualActive) {
            root.enable();
        } else {
            root.disable();
        }
    }
}
