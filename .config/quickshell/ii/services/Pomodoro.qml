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
    property int cyclesBeforeLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak
    property string alertSound: Config.options.time.pomodoro.alertSound

    property bool isPomodoroRunning: Persistent.states.timer.pomodoro.running
    property bool isBreak: Persistent.states.timer.pomodoro.isBreak
    property bool isLongBreak: Persistent.states.timer.pomodoro.isLongBreak
    property bool isPomodoroLongBreak: Persistent.states.timer.pomodoro.isLongBreak
    property int pomodoroLapDuration: isBreak ? (isLongBreak ? longBreakTime : breakTime) : focusTime
    property int pomodoroSecondsLeft: focusTime
    property int pomodoroCycle: Persistent.states.timer.pomodoro.cycle

    property bool isStopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // General
    Component.onCompleted: {
        if (!isStopwatchRunning) stopwatchReset()
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000)
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10)
    }

    // Pomodoro
    function refreshPomodoro() {
        // Work <-> break ?
        if (getCurrentTimeInSeconds() >= Persistent.states.timer.pomodoro.start + pomodoroLapDuration) {
            // Reset counts
            const currentTimeInSeconds = getCurrentTimeInSeconds()
            Persistent.states.timer.pomodoro.isBreak = !Persistent.states.timer.pomodoro.isBreak
            Persistent.states.timer.pomodoro.isLongBreak = Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak)
            Persistent.states.timer.pomodoro.start = currentTimeInSeconds

            // Send notification
            let notificationTitle, notificationMessage
            if (Persistent.states.timer.pomodoro.isBreak && pomodoroCycle % cyclesBeforeLongBreak === 0) {  // isPomodoroLongBreak
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(longBreakTime / 60))
            } else if (Persistent.states.timer.pomodoro.isBreak) {
                notificationMessage = Translation.tr(`Relax for %1 minutes`).arg(Math.floor(breakTime / 60))
            } else {
                notificationMessage = Translation.tr(`Focus for %1 minutes`).arg(Math.floor(focusTime / 60))
            }

            Quickshell.execDetached(["notify-send", "Pomodoro", notificationMessage, "-a", "Shell"])
            if (alertSound) {  // Play sound only if alertSound is explicitly specified
                Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", alertSound])
            }

            if (!isBreak) {
                Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
            }
        }

        pomodoroSecondsLeft = pomodoroLapDuration - (getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start)
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.isPomodoroRunning
        repeat: true
        onTriggered: refreshPomodoro()
    }

    function togglePomodoro() {
        Persistent.states.timer.pomodoro.running = !isPomodoroRunning
        if (Persistent.states.timer.pomodoro.running) { // Start/Resume
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds() + pomodoroSecondsLeft - pomodoroLapDuration
        }
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false
        Persistent.states.timer.pomodoro.isBreak = false
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds()
        Persistent.states.timer.pomodoro.cycle = 0
        refreshPomodoro()
    }

    // Stopwatch
    function refreshStopwatch() {  // Stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: root.isStopwatchRunning
        repeat: true
        onTriggered: refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.isStopwatchRunning)
            stopwatchPause()
        else
            stopwatchResume()
    }

    function stopwatchPause() {
        Persistent.states.timer.stopwatch.running = false
    }

    function stopwatchResume() {
        Persistent.states.timer.stopwatch.running = true
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms() - stopwatchTime
    }

    function stopwatchReset() {
        Persistent.states.timer.stopwatch.running = false
        stopwatchTime = 0
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms()
        Persistent.states.timer.stopwatch.laps = []
    }

    function stopwatchRecordLap() {
        Persistent.states.timer.stopwatch.laps.push(stopwatchTime)
    }
}
