pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.ii.island

// Mirrors end-4's pomodoro and stopwatch into the pill. TimerService does the ticking;
// this only reacts to its property changes, so there is no timer of our own.
Item {
    id: root

    property int lastStopwatchSecond: -1 // stopwatchTime is 10 ms units; update once per second

    function mmss(totalSeconds) {
        const s = Math.max(0, Math.floor(totalSeconds));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    function syncPomodoro() {
        if (!TimerService.pomodoroRunning) {
            IslandState.clearActivity("pomodoro");
            return;
        }
        const brk = TimerService.pomodoroBreak;
        const lap = TimerService.pomodoroLapDuration;
        const left = TimerService.pomodoroSecondsLeft;
        IslandState.setActivity("pomodoro", {
            icon: brk ? "coffee" : "timer",
            text: (brk ? Translation.tr("Break %1") : Translation.tr("Focus %1")).arg(root.mmss(left)),
            progress: lap > 0 ? Math.min(1, Math.max(0, 1 - left / lap)) : -1,
            priority: 60
        });
    }

    function syncStopwatch() {
        if (!TimerService.stopwatchRunning) {
            root.lastStopwatchSecond = -1;
            IslandState.clearActivity("stopwatch");
            return;
        }
        const s = Math.floor(TimerService.stopwatchTime / 100);
        if (s === root.lastStopwatchSecond)
            return; // same second, skip the repaint
        root.lastStopwatchSecond = s;
        IslandState.setActivity("stopwatch", { icon: "timer_play", text: root.mmss(s), priority: 40 });
    }

    Connections {
        target: TimerService
        function onPomodoroRunningChanged() { root.syncPomodoro(); }
        function onPomodoroSecondsLeftChanged() { root.syncPomodoro(); }
        function onPomodoroBreakChanged() {
            root.syncPomodoro();
            // The service also flips break when reset or stopped, but it stops the timer
            // first, so only a flip while running is a real lap end.
            if (!TimerService.pomodoroRunning)
                return;
            if (TimerService.pomodoroBreak)
                IslandState.pushCard("pomodoro", { icon: "coffee", title: Translation.tr("Focus done — take a break"), body: "", ttl: 6000 });
            else
                IslandState.pushCard("pomodoro", { icon: "timer", title: Translation.tr("Break over — back to it"), body: "", ttl: 6000 });
        }
        function onStopwatchRunningChanged() { root.syncStopwatch(); }
        function onStopwatchTimeChanged() { root.syncStopwatch(); }
    }

    Component.onCompleted: {
        root.syncPomodoro();
        root.syncStopwatch();
    }
}
