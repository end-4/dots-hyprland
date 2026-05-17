import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth
    readonly property color stateColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : Appearance.colors.colSecondaryContainer
    readonly property color stateTextColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnSecondaryContainer
    readonly property string stateLabel: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
    readonly property int cyclePosition: TimerService.pomodoroCycle + 1

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 10

        // The Pomodoro timer circle
        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            lineWidth: 10
            value: {
                return TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration;
            }
            implicitSize: 200
            colPrimary: root.stateTextColor
            colSecondary: root.stateColor
            enableAnimation: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        let minutes = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, '0');
                        let seconds = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, '0');
                        return `${minutes}:${seconds}`;
                    }
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: 40
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.stateLabel
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            Rectangle {
                radius: Appearance.rounding.full
                color: root.stateColor
                
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                implicitWidth: 58
                implicitHeight: 36

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 3

                    MaterialSymbol {
                        text: "repeat"
                        iconSize: 14
                        color: root.stateTextColor
                    }

                    StyledText {
                        id: cycleText
                        font.family: Appearance.font.family.monospace
                        font.weight: Font.DemiBold
                        color: root.stateTextColor
                        text: `${root.cyclePosition}/${TimerService.cyclesBeforeLongBreak}`
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 210
            Layout.preferredHeight: 30
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer2

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    text: TimerService.pomodoroBreak ? "coffee" : "search_activity"
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.stateTextColor
                }

                StyledText {
                    text: root.stateLabel
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5

            Repeater {
                model: TimerService.cyclesBeforeLongBreak

                Rectangle {
                    required property int index
                    implicitWidth: index === TimerService.pomodoroCycle ? 18 : 8
                    implicitHeight: 8
                    radius: Appearance.rounding.full
                    color: index <= TimerService.pomodoroCycle ? root.stateTextColor : Appearance.colors.colLayer2

                    Behavior on implicitWidth {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }

        // The Start/Stop and Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            RippleButton {
                buttonRadius: Appearance.rounding.full
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.pomodoroRunning ? Translation.tr("Pause") : (TimerService.pomodoroSecondsLeft === TimerService.focusTime) ? Translation.tr("Start") : Translation.tr("Resume")
                    color: TimerService.pomodoroRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                }
                implicitHeight: 38
                implicitWidth: 96
                font.pixelSize: Appearance.font.pixelSize.larger
                onClicked: TimerService.togglePomodoro()
                colBackground: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
            }

            RippleButton {
                buttonRadius: Appearance.rounding.full
                implicitHeight: 38
                implicitWidth: 96

                onClicked: TimerService.resetPomodoro()
                enabled: (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration) || TimerService.pomodoroCycle > 0 || TimerService.pomodoroBreak

                font.pixelSize: Appearance.font.pixelSize.larger
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Reset")
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }
    }
}
