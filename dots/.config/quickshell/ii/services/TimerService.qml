pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
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

    property bool pomodoroRunning: Persistent.states.timer.pomodoro.running
    property bool pomodoroBreak: Persistent.states.timer.pomodoro.isBreak
    property bool pomodoroLongBreak: Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak);
    property int pomodoroLapDuration: pomodoroLongBreak ? longBreakTime : pomodoroBreak ? breakTime : focusTime // This is a binding that's to be kept
    property int pomodoroSecondsLeft: pomodoroLapDuration // Reasonable init value, to be changed
    property int pomodoroCycle: Persistent.states.timer.pomodoro.cycle

    // When the configured duration changes while the timer is paused, show the new value immediately
    onPomodoroLapDurationChanged: {
        if (!pomodoroRunning) pomodoroSecondsLeft = pomodoroLapDuration;
    }

    property bool stopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // General
    Component.onCompleted: {
        if (!stopwatchRunning)
            stopwatchReset();
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000);
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10);
    }

    // Pomodoro
    function refreshPomodoro() {
        // Work <-> break ?
        if (getCurrentTimeInSeconds() >= Persistent.states.timer.pomodoro.start + pomodoroLapDuration) {
            const wasBreak = pomodoroBreak;
            Persistent.states.timer.pomodoro.isBreak = !wasBreak;
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();

            // Skip zero-duration break phases: go straight to the next focus session
            if (!wasBreak) {
                const enteringLongBreak = (pomodoroCycle + 1 == cyclesBeforeLongBreak);
                const newBreakDuration = enteringLongBreak ? longBreakTime : breakTime;
                if (newBreakDuration === 0) {
                    Persistent.states.timer.pomodoro.isBreak = false;
                    Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
                    Quickshell.execDetached(["notify-send", "Pomodoro",
                        Translation.tr(`🔴 Focus: %1 minutes`).arg(Math.floor(focusTime / 60)), "-a", "Shell"]);
                    playPomodoroAlarm();
                    pomodoroSecondsLeft = pomodoroLapDuration;
                    return;
                }
            }

            // Send notification for the new phase
            let notificationMessage;
            if (Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak)) {
                notificationMessage = Translation.tr(`🌿 Long break: %1 minutes`).arg(Math.floor(longBreakTime / 60));
            } else if (Persistent.states.timer.pomodoro.isBreak) {
                notificationMessage = Translation.tr(`☕ Break: %1 minutes`).arg(Math.floor(breakTime / 60));
            } else {
                notificationMessage = Translation.tr(`🔴 Focus: %1 minutes`).arg(Math.floor(focusTime / 60));
            }

            Quickshell.execDetached(["notify-send", "Pomodoro", notificationMessage, "-a", "Shell"]);
            playPomodoroAlarm();

            if (!pomodoroBreak) {
                Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
            }
        }

        pomodoroSecondsLeft = pomodoroLapDuration > 0
            ? pomodoroLapDuration - (getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start)
            : 0;
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.pomodoroRunning
        repeat: true
        onTriggered: refreshPomodoro()
    }

    function playPomodoroAlarm() {
        if (!Config.options.sounds.pomodoro) return;
        const vol = String(Config.options.time.pomodoro.alarmVolume);
        const base = `/usr/share/sounds/${Audio.audioTheme}/stereo/alarm-clock-elapsed`;
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", "-volume", vol, base + ".oga"]);
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", "-volume", vol, base + ".ogg"]);
    }

    function skipPomodoro() {
        const wasBreak = pomodoroBreak;
        Persistent.states.timer.pomodoro.isBreak = !wasBreak;
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();

        // Skip zero-duration break phases (mirrors refreshPomodoro logic)
        if (!wasBreak) {
            const enteringLongBreak = (pomodoroCycle + 1 == cyclesBeforeLongBreak);
            const newBreakDuration = enteringLongBreak ? longBreakTime : breakTime;
            if (newBreakDuration === 0) {
                Persistent.states.timer.pomodoro.isBreak = false;
                Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
                pomodoroSecondsLeft = pomodoroLapDuration;
                return;
            }
        }

        if (wasBreak) {
            Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
        }

        pomodoroSecondsLeft = pomodoroLapDuration;
    }

    function togglePomodoro() {
        Persistent.states.timer.pomodoro.running = !pomodoroRunning;
        if (Persistent.states.timer.pomodoro.running) {
            // Start/Resume
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds() + pomodoroSecondsLeft - pomodoroLapDuration;
        }
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false;
        Persistent.states.timer.pomodoro.isBreak = false;
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();
        Persistent.states.timer.pomodoro.cycle = 0;
        refreshPomodoro();
    }

    // Stopwatch
    function refreshStopwatch() {  // Stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart;
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: root.stopwatchRunning
        repeat: true
        onTriggered: refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.stopwatchRunning)
            stopwatchPause();
        else
            stopwatchResume();
    }

    function stopwatchPause() {
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchResume() {
        if (stopwatchTime === 0) Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = true;
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms() - stopwatchTime;
    }

    function stopwatchReset() {
        stopwatchTime = 0;
        Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchRecordLap() {
        Persistent.states.timer.stopwatch.laps.push(stopwatchTime);
    }
}
