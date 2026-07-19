pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

FooterRectangle {
    Layout.fillWidth: true
    implicitWidth: 0
    color: Looks.colors.bgPanelBody

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
            topMargin: 12
            bottomMargin: 12
        }
        spacing: 0

        SmallBorderedIconButton {
            visible: !TimerService.pomodoroRunning
            icon.name: "subtract"
            onClicked: Config.options.time.pomodoro.focus -= 300 // 5 mins
        }

        WTextWithFixedWidth {
            visible: !TimerService.pomodoroRunning
            implicitWidth: 81
            horizontalAlignment: Text.AlignHCenter
            color: Looks.colors.subfg
            text: Translation.tr("%1 mins").arg(`<font color="${Looks.colors.fg.toString()}">${TimerService.focusTime / 60}</font>`)
        }

        SmallBorderedIconButton {
            visible: !TimerService.pomodoroRunning
            icon.name: "add"
            onClicked: Config.options.time.pomodoro.focus += 300 // 5 mins
        }

        WText {
            visible: TimerService.pomodoroRunning
            font.pixelSize: Looks.font.pixelSize.large
            text: Translation.tr("Focusing")
        }

        Item {
            Layout.fillWidth: true
        }

        SmallBorderedIconAndTextButton {
            iconName: TimerService.pomodoroRunning ? "stop" : "play"
            text: TimerService.pomodoroRunning ? Translation.tr("End session") : Translation.tr("Focus")

            onClicked: {
                if (TimerService.pomodoroRunning) {
                    TimerService.togglePomodoro();
                    TimerService.resetPomodoro();
                } else {
                    TimerService.togglePomodoro();
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarRight", "toggle"]);
                }
            }
        }
    }
}
