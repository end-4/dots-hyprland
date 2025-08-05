pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple Pomodoro time manager.
 */
Singleton {
    id: root

    property int pomodoroFocusTime: Config.options.time.pomodoro.focus
    property int pomodoroBreakTime: Config.options.time.pomodoro.breakTime
    property int pomodoroLongBreakTime: Config.options.time.pomodoro.longBreak
    property int pomodoroLongBreakCycle: Config.options.time.pomodoro.cycle
    property bool isPomodoroRunning: Config.options.time.pomodoro.running

    property int pomodoroTimeLeft: pomodoroFocusTime
    property int getPomodoroSecondsLeft: pomodoroFocusTime
    property int pomodoroTimeStarted: getCurrentTimeInSeconds()  // The time pomodoro was last Resumed
    property bool isPomodoroBreak: false
    property int pomodoroCycle: 1

    property int stopwatchTime: 0
    property bool isStopwatchRunning: false
    property int stopwatchStartTime: 0
    property var stopwatchLaps: []

    // Start and Stop button
    function togglePomodoro() {
        Config.options.time.pomodoro.running = !isPomodoroRunning
        if (isPomodoroRunning) {  // Pressed Start button
            pomodoroTimeStarted = getCurrentTimeInSeconds()
        } else {  // Pressed Stop button
            pomodoroTimeLeft -= (getCurrentTimeInSeconds() - pomodoroTimeStarted)
        }
    }

    // Reset button
    function pomodoroReset() {
        pomodoroTimeLeft = pomodoroFocusTime
        getPomodoroSecondsLeft = pomodoroFocusTime
        isPomodoroBreak = false
        Config.options.time.pomodoro.running = false
        pomodoroCycle = 1
    }

    function tickSecond() {
        if (getCurrentTimeInSeconds() >= pomodoroTimeStarted + pomodoroTimeLeft) {
            isPomodoroBreak = !isPomodoroBreak
            pomodoroTimeStarted += pomodoroTimeLeft
            pomodoroTimeLeft = isPomodoroBreak ? pomodoroBreakTime : pomodoroFocusTime

            let notificationTitle, notificationMessage

            if (isPomodoroBreak && pomodoroCycle % pomodoroLongBreakCycle === 0) {  // isPomodoroLongBreak
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(pomodoroLongBreakTime / 60))
            } else if (isPomodoroBreak) {
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(pomodoroBreakTime / 60))
            } else {
                notificationMessage = Translation.tr(`Focus for %1 minutes`).arg(Math.floor(pomodoroFocusTime / 60))
                pomodoroCycle += 1
            }

            Quickshell.execDetached(["notify-send", "Pomodoro", notificationMessage, "-a", "Shell"])
        }

        // A nice abstraction for resume logic by updating the TimeStarted
        getPomodoroSecondsLeft = (pomodoroTimeStarted + pomodoroTimeLeft) - getCurrentTimeInSeconds()
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000)
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10)
    }

    function tick10ms() {  // stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStartTime
    }

    // Stopwatch functions
    function toggleStopwatch() {
        isStopwatchRunning = !isStopwatchRunning
        if (isStopwatchRunning) {
            // Resume from paused time by adjusting start time
            stopwatchStartTime = getCurrentTimeIn10ms() - stopwatchTime
        }
    }

    function stopwatchReset() {
        if (isStopwatchRunning) {  // Clicked on Lap
            stopwatchLaps.unshift(stopwatchTime)  // Last lap goes first on list
            // Reassign to trigger onListChanged, idk copied from Todo.qml
            root.stopwatchLaps = stopwatchLaps.slice(0)
        } else {  // Clicked on Reset
            isStopwatchRunning = false
            stopwatchTime = 0
            stopwatchStartTime = 0
            stopwatchLaps = []
        }
    }
}
