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
    property bool isBreak: Persistent.states.timer.pomodoro.isBreak
    property bool isPomodoroReset: !isPomodoroRunning
    property int timeLeft: focusTime
    property int pomodoroSecondsLeft: focusTime
    property int pomodoroStart: Persistent.states.timer.pomodoro.start
    property int pomodoroCycle: 1

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
        if (getCurrentTimeInSeconds() >= pomodoroStart + timeLeft) {
            Persistent.states.timer.pomodoro.isBreak = !isBreak
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
                Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", alertSound])
            }
        }

        // A nice abstraction for resume logic by updating the TimeStarted
        pomodoroSecondsLeft = (pomodoroStart + timeLeft) - getCurrentTimeInSeconds()
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.isPomodoroRunning
        repeat: true
        onTriggered: Pomodoro.refreshPomodoro()
    }

    function togglePomodoro() {
        isPomodoroReset = false
        Persistent.states.timer.pomodoro.running = !isPomodoroRunning
        if (isPomodoroRunning) {  // Pressed Start button
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds()
        } else {  // Pressed Stop button
            timeLeft -= (getCurrentTimeInSeconds() - pomodoroStart)
        }
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false
        Persistent.states.timer.pomodoro.isBreak = false
        isPomodoroReset = true
        timeLeft = focusTime
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds()
        pomodoroCycle = 1
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
        onTriggered: root.refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.isStopwatchRunning)
            root.stopwatchPause()
        else
            root.stopwatchResume()
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
