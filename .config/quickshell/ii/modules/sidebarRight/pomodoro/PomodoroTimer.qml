import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        RowLayout {
            spacing: 40
            // The Pomodoro timer circle
            CircularProgress {
                Layout.alignment: Qt.AlignHCenter
                lineWidth: 7
                gapAngle: Math.PI / 14
                value: {
                    let pomodoroTotalTime = Pomodoro.isBreak ? Pomodoro.breakTime : Pomodoro.focusTime
                    return Pomodoro.getPomodoroSecondsLeft / pomodoroTotalTime
                }
                size: 125
                primaryColor: Appearance.m3colors.m3onSecondaryContainer
                secondaryColor: Appearance.colors.colSecondaryContainer
                enableAnimation: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            let minutes = Math.floor(Pomodoro.getPomodoroSecondsLeft / 60).toString().padStart(2, '0')
                            let seconds = Math.floor(Pomodoro.getPomodoroSecondsLeft % 60).toString().padStart(2, '0')
                            return `${minutes}:${seconds}`
                        }
                        font.pixelSize: Appearance.font.pixelSize.hugeass + 4
                        color: Appearance.m3colors.m3onSurface
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.isBreak ? Translation.tr("Break") : Translation.tr("Focus")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                    }
                }
            }

            // The Start/Stop and Reset buttons
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                RippleButton {
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Pomodoro.isPomodoroRunning ? Translation.tr("Pause") : (Pomodoro.getPomodoroSecondsLeft === Pomodoro.focusTime) ? Translation.tr("Start") : Translation.tr("Resume")
                        color: Pomodoro.isPomodoroRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                    }
                    implicitHeight: 35
                    implicitWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.larger
                    onClicked: Pomodoro.togglePomodoro()
                    colBackground: Pomodoro.isPomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                    colBackgroundHover: Pomodoro.isPomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                }

                RippleButton {
                    implicitHeight: 35
                    implicitWidth: 90

                    onClicked: Pomodoro.pomodoroReset()
                    enabled: (Pomodoro.getPomodoroSecondsLeft < Pomodoro.focusTime)

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

        // The SpinBoxes for adjusting duration
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 2
            uniformCellWidths: true
            columnSpacing: 20
            rowSpacing: 4

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Focus")
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Break")
            }

            ConfigSpinBox {
                id: focusSpinBox
                spacing: 0
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                value: Config.options.time.pomodoro.focus / 60
                onValueChanged: {
                    Config.options.time.pomodoro.focus = value * 60
                    if (Pomodoro.isPomodoroReset) {  // Special case for Pomodoro in Reset state
                        Pomodoro.getPomodoroSecondsLeft = Pomodoro.focusTime
                        Pomodoro.timeLeft = Pomodoro.focusTime
                    }
                }
            }

            ConfigSpinBox {
                id: breakSpinBox
                spacing: 0
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                value: Config.options.time.pomodoro.breakTime / 60
                onValueChanged: {
                    Config.options.time.pomodoro.breakTime = value * 60
                }
            }

            StyledText {
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Cycle")
            }
            StyledText {
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Long break")
            }

            ConfigSpinBox {
                id: cycleSpinBox
                spacing: 0
                from: 1
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                value: Config.options.time.pomodoro.cycle
                onValueChanged: {
                    Config.options.time.pomodoro.cycle = value
                }
            }

            ConfigSpinBox {
                id: longBreakSpinBox
                spacing: 0
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                value: Config.options.time.pomodoro.longBreak / 60
                onValueChanged: {
                    Config.options.time.pomodoro.longBreak = value * 60
                }
            }
        }
    }
}