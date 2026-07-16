import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var tabButtonList: [
        {"name": Translation.tr("Pomodoro"), "icon": "search_activity"},
        {"name": Translation.tr("Stopwatch"), "icon": "timer"}
    ]

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                tabBar.incrementCurrentIndex();
            } else if (event.key === Qt.Key_PageUp) {
                tabBar.decrementCurrentIndex();
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_S) {
            if (tabBar.currentIndex === 0) {
                TimerService.togglePomodoro()
            } else {
                TimerService.toggleStopwatch()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_R) {
            if (tabBar.currentIndex === 0) {
                TimerService.resetPomodoro()
            } else {
                TimerService.stopwatchReset()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_L) {
            TimerService.stopwatchRecordLap()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SecondaryTabBar {
            id: tabBar
            currentIndex: swipeView.currentIndex

            Repeater {
                model: root.tabButtonList
                delegate: SecondaryTabButton {
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                }
            }
        }

        Item {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            property int currentIndex: tabBar.currentIndex

            PomodoroTimer {
                width: parent.width
                height: parent.height
                x: (0 - swipeView.currentIndex) * (parent.width + 30)
                opacity: swipeView.currentIndex === 0 ? 1 : 0
                scale: swipeView.currentIndex === 0 ? 1 : 0.96

                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }

            Stopwatch {
                width: parent.width
                height: parent.height
                x: (1 - swipeView.currentIndex) * (parent.width + 30)
                opacity: swipeView.currentIndex === 1 ? 1 : 0
                scale: swipeView.currentIndex === 1 ? 1 : 0.96

                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }
        }
    }
}
