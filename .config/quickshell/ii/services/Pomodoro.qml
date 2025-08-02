pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple Pomodoro time manager.
 */
Singleton {
    id: root

    property int pomodoroWorkTime: 25 * 60  // 25 minutes in seconds
    property int pomodoroBreakTime: 5 * 60  // 5 minutes in seconds
    property int pomodoroTime: pomodoroWorkTime
    property bool isPomodoroRunning: false
    property bool isPomodoroBreak: false
    property int stopwatchTime: 0
    property bool isStopwatchRunning: false

    function togglePomodoro() {
        isPomodoroRunning = !isPomodoroRunning;
    }

    function toggleStopwatch() {
        isStopwatchRunning = !isStopwatchRunning;
    }

    function pomodoroReset() {
        pomodoroTime = pomodoroWorkTime;
        isPomodoroRunning = false;
        isPomodoroBreak = false;
    }

    function stopwatchReset() {
        stopwatchTime = 0;
        isStopwatchRunning = false;
    }

    function tickSecond() {
        if (pomodoroTime > 0) {
            pomodoroTime--;
        } else {
            isPomodoroBreak = !isPomodoroBreak;
            pomodoroTime = isPomodoroBreak ? pomodoroBreakTime : pomodoroWorkTime;
            if (isPomodoroBreak) {
                Quickshell.execDetached(["bash", "-c", `notify-send "☕ Short Break!" "Relax for ${Math.floor(pomodoroBreakTime / 60)} minutes."`]);
            } else {
                Quickshell.execDetached(["bash", "-c", `notify-send "🔴 Pomodoro started!" "Focus for ${Math.floor(pomodoroWorkTime / 60)} minutes."`]);
            }
        }
    }

    function timeFormattedPomodoro() {
        let minutes = Math.floor(pomodoroTime / 60);
        let seconds = Math.floor(pomodoroTime % 60);
        return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }

    function timeFormattedStopwatch() {
        let totalSeconds = Math.floor(stopwatchTime);
        let hours = Math.floor(totalSeconds / 3600);
        let minutes = Math.floor((totalSeconds % 3600) / 60);
        let seconds = Math.floor(totalSeconds % 60);
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
}
