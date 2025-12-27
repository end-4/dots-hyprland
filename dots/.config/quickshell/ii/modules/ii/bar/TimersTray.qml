import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick.Controls

BarGroup {
    id: root

    readonly property bool pRunning: TimerService.pomodoroRunning ?? false
    readonly property bool sRunning: TimerService.stopwatchRunning ?? false
    readonly property bool hasStop: TimerService.stopwatchTime > 0
    readonly property bool hasPomo: TimerService.pomodoroSecondsLeft > 0 &&
    (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration || pRunning)

    visible: hasStop || hasPomo

    implicitWidth: visible ? (mainRow.implicitWidth + 20) : 0
    implicitHeight: Appearance.sizes.baseBarHeight
    Layout.preferredWidth: implicitWidth

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 15

        // --- POMODORO SECTION ---
        RowLayout {
            visible: (root.pRunning && root.sRunning) || (!root.sRunning && root.hasPomo)
            spacing: 5

            MaterialSymbol {
                text: "search_activity"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
            StyledText {
                text: {
                    const t = TimerService.pomodoroSecondsLeft
                    return Math.floor(t/60).toString().padStart(2,'0') + ":" + (t%60).toString().padStart(2,'0')
                }
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // --- STOPWATCH SECTION ---
        RowLayout {
            visible: root.sRunning || (root.hasStop && !root.hasPomo)
            spacing: 5

            MaterialSymbol {
                text: "timer"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
            StyledText {
                text: {
                    const t = TimerService.stopwatchTime
                    const sec = Math.floor(t/100)
                    return Math.floor(sec/60).toString().padStart(2,'0') + ":" +
                    (sec%60).toString().padStart(2,'0') + "." +
                    (t%100).toString().padStart(2,'0')
                }
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
