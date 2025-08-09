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

    property int focusTime: Config.options.time.pomodoro.focus
    property int breakTime: Config.options.time.pomodoro.breakTime
    property int longBreakTime: Config.options.time.pomodoro.longBreak
    property int longBreakCycle: Config.options.time.pomodoro.cycle
    property string alertSound: Config.options.time.pomodoro.alertSound

    property bool isPomodoroRunning: Persistent.states.timer.pomodoro.running
    property bool isBreak: false
    property bool isPomodoroReset: !isPomodoroRunning
    property int timeLeft: focusTime
    property int getPomodoroSecondsLeft: focusTime
    property int pomodoroStartTime: Persistent.states.timer.pomodoro.start
    property int pomodoroCycle: 1

    property bool isStopwatchRunning: false
    property int stopwatchTime: 0
    property int stopwatchStart: 0
    property var stopwatchLaps: []

    // Start and Stop button
    function togglePomodoro() {
        isPomodoroReset = false
        Persistent.states.timer.pomodoro.running = !isPomodoroRunning
        if (isPomodoroRunning) {  // Pressed Start button
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds()
        } else {  // Pressed Stop button
            timeLeft -= (getCurrentTimeInSeconds() - pomodoroStartTime)
        }
    }

    // Reset button
    function pomodoroReset() {
        Persistent.states.timer.pomodoro.running = false
        isBreak = false
        isPomodoroReset = true
        timeLeft = focusTime
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds()
        pomodoroCycle = 1
        refreshPomodoro()
    }

    function refreshPomodoro() {
        if (getCurrentTimeInSeconds() >= pomodoroStartTime + timeLeft) {
            isBreak = !isBreak
            Persistent.states.timer.pomodoro.start += timeLeft
            timeLeft = isBreak ? breakTime : focusTime

            let notificationTitle, notificationMessage

            if (isBreak && pomodoroCycle % longBreakCycle === 0) {  // isPomodoroLongBreak
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(longBreakTime / 60))
            } else if (isBreak) {
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(breakTime / 60))
            } else {
                notificationMessage = Translation.tr(`Focus for %1 minutes`).arg(Math.floor(focusTime / 60))
                pomodoroCycle += 1
            }

            Quickshell.execDetached(["notify-send", "Pomodoro", notificationMessage, "-a", "Shell"])
            if (alertSound) {  // Play sound only if alertSound is explicitly specified
                Quickshell.execDetached(["bash", "-c", `ffplay -nodisp -autoexit ${alertSound}`])
            }
        }

        // A nice abstraction for resume logic by updating the TimeStarted
        getPomodoroSecondsLeft = (pomodoroStartTime + timeLeft) - getCurrentTimeInSeconds()
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000)
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10)
    }

    function refreshStopwatch() {  // stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart
    }

    // Stopwatch functions
    function toggleStopwatch() {
        isStopwatchRunning = !isStopwatchRunning
        if (isStopwatchRunning) {
            // Resume from paused time by adjusting start time
            stopwatchStart = getCurrentTimeIn10ms() - stopwatchTime
        }
    }

    function stopwatchResetOrLaps() {
        if (isStopwatchRunning) {  // Clicked on Lap
            recordLaps()
        } else {  // Clicked on Reset
            stopwatchReset()
        }
    }

    function stopwatchReset() {
            isStopwatchRunning = false
            stopwatchTime = 0
            stopwatchStart = 0
            stopwatchLaps = []
    }

    function recordLaps() {
            stopwatchLaps.unshift(stopwatchTime)  // Last lap goes first on list
            // Reassign to trigger onListChanged, idk copied from Todo.qml
            root.stopwatchLaps = stopwatchLaps.slice(0)
    }
}
