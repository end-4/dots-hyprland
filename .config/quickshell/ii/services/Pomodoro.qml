pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common

import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple Pomodoro time manager.
 */
Singleton {
    id: root

    // TODO: read these values from a config file.
    property int pomodoroFocusTime: Config.options.time.pomodoro.focus
    property int pomodoroBreakTime: Config.options.time.pomodoro.breaktime
    property int pomodoroLongBreakTime: Config.options.time.pomodoro.longbreak
    property int pomodoroLongBreakCycle: Config.options.time.pomodoro.cycle

    property int pomodoroTimeLeft: pomodoroFocusTime
    property int getPomodoroSecondsLeft: pomodoroFocusTime
    property int pomodoroTimeStarted: getCurrentTime()  // The time pomodoro was last Resumed
    property bool isPomodoroBreak: false
    property bool isPomodoroRunning: false
    property int pomodoroCycle: 1

    property int stopwatchTime: 0
    property bool isStopwatchRunning: false

    // Pause and Resume button
    function togglePomodoro() {
        isPomodoroRunning = !isPomodoroRunning
        if (isPomodoroRunning) {  // Pressed Start button
            pomodoroTimeStarted = getCurrentTime()
        } else {  // Pressed Pause button
            pomodoroTimeLeft -= (getCurrentTime() - pomodoroTimeStarted)
        }
    }

    // Reset button
    function pomodoroReset() {
        pomodoroTimeLeft = pomodoroFocusTime
        getPomodoroSecondsLeft = pomodoroFocusTime
        isPomodoroBreak = false
        isPomodoroRunning = false
    }

    function tickSecond() {
        if (getCurrentTime() >= pomodoroTimeStarted + pomodoroTimeLeft) {
            isPomodoroBreak = !isPomodoroBreak
            pomodoroTimeStarted += pomodoroTimeLeft
            pomodoroTimeLeft  = isPomodoroBreak ? pomodoroBreakTime : pomodoroFocusTime

            if (isPomodoroBreak && pomodoroCycle % pomodoroLongBreakCycle == 0) {  // isPomodoroLongBreak
                Quickshell.execDetached([
                    "notify-send",
                    Translation.tr("🌿 Long Break!"),
                    Translation.tr(`Relax for %1 minutes.`).arg(Math.floor(pomodoroLongBreakTime / 60))
                ])
            } else if(isPomodoroBreak){
                Quickshell.execDetached([
                    "notify-send",
                    Translation.tr("☕ Short Break!"),
                    Translation.tr(`Relax for %1 minutes.`).arg(Math.floor(pomodoroBreakTime / 60))
                ])
            } else {
                Quickshell.execDetached([
                    "notify-send",
                    Translation.tr("🔴 Pomodoro started!"),
                    Translation.tr(`Focus for %1 minutes.`).arg(Math.floor(pomodoroFocusTime / 60))
                ])
                pomodoroCycle += 1
            }
        }

        getPomodoroSecondsLeft = (pomodoroTimeStarted + pomodoroTimeLeft) - getCurrentTime()
    }

    function getCurrentTime() {
        return Math.floor(Date.now() / 1000)
    }

    // Stopwatch functions
    function toggleStopwatch() {
        isStopwatchRunning = !isStopwatchRunning
    }

    function stopwatchReset() {
        stopwatchTime = 0
        isStopwatchRunning = false
    }
}
