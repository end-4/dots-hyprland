import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    // Fully stopped = no session (never started or reset)
    readonly property bool sessionIdle: !TimerService.pomodoroRunning
        && TimerService.pomodoroSecondsLeft === TimerService.focusTime
        && !TimerService.pomodoroBreak
        && TimerService.pomodoroCycle === 0
    property bool settingsOpen: false

    onSessionIdleChanged: {
        if (!sessionIdle)
            settingsOpen = false;
    }

    implicitHeight: flickable.height
    implicitWidth: flickable.width

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: contentColumn
            x: 16
            width: flickable.width - 32
            spacing: 0

            // The Pomodoro timer circle
            CircularProgress {
                Layout.alignment: Qt.AlignHCenter
                lineWidth: 8
                value: {
                    return TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration;
                }
                implicitSize: 200
                enableAnimation: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            let minutes = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, '0');
                            let seconds = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, '0');
                            return `${minutes}:${seconds}`;
                        }
                        font.pixelSize: 40
                        color: Appearance.m3colors.m3onSurface
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }

                Rectangle {
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer2
                    visible: !root.sessionIdle
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    implicitWidth: 36
                    implicitHeight: implicitWidth

                    StyledText {
                        anchors.centerIn: parent
                        color: Appearance.colors.colOnLayer2
                        text: TimerService.pomodoroCycle + 1
                    }
                }
            }

            // Controls row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 10

                RippleButton {
                    visible: root.sessionIdle
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Start")
                        color: Appearance.colors.colOnPrimary
                    }
                    implicitHeight: 35
                    implicitWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.larger
                    onClicked: TimerService.togglePomodoro()
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                }

                RippleButton {
                    visible: root.sessionIdle
                    implicitHeight: 35
                    implicitWidth: 90
                    toggled: root.settingsOpen
                    onClicked: root.settingsOpen = !root.settingsOpen
                    colBackground: root.settingsOpen ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1
                    colBackgroundHover: root.settingsOpen ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                    colRipple: root.settingsOpen ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colLayer1Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    font.pixelSize: Appearance.font.pixelSize.larger
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: root.settingsOpen ? Translation.tr("Hide") : Translation.tr("Settings")
                        color: root.settingsOpen ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.larger
                    }
                }

                RippleButton {
                    visible: !root.sessionIdle
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: TimerService.pomodoroRunning ? Translation.tr("Pause") : Translation.tr("Resume")
                        color: TimerService.pomodoroRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                    }
                    implicitHeight: 35
                    implicitWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.larger
                    onClicked: TimerService.togglePomodoro()
                    colBackground: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                    colBackgroundHover: TimerService.pomodoroRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                }

                RippleButton {
                    visible: !root.sessionIdle
                    implicitHeight: 35
                    implicitWidth: 90
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

            // Collapsible settings content (no extra card/title)
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                visible: root.sessionIdle && root.settingsOpen
                columns: 2
                columnSpacing: 12
                rowSpacing: 6

                StyledText {
                    text: Translation.tr("Focus")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledText {
                    text: Translation.tr("Break")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledSpinBox {
                    from: 1
                    to: 60
                    value: Config.options.time.pomodoro.focus / 60
                    stepSize: 1
                    Layout.preferredWidth: 86
                    onValueChanged: Config.options.time.pomodoro.focus = value * 60
                }
                StyledSpinBox {
                    from: 1
                    to: 30
                    value: Config.options.time.pomodoro.breakTime / 60
                    stepSize: 1
                    Layout.preferredWidth: 86
                    onValueChanged: Config.options.time.pomodoro.breakTime = value * 60
                }

                StyledText {
                    text: Translation.tr("Long break")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledText {
                    text: Translation.tr("Cycles")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignHCenter
                }
                StyledSpinBox {
                    from: 5
                    to: 45
                    value: Config.options.time.pomodoro.longBreak / 60
                    stepSize: 1
                    Layout.preferredWidth: 86
                    onValueChanged: Config.options.time.pomodoro.longBreak = value * 60
                }
                StyledSpinBox {
                    from: 2
                    to: 10
                    value: Config.options.time.pomodoro.cyclesBeforeLongBreak
                    stepSize: 1
                    Layout.preferredWidth: 86
                    onValueChanged: Config.options.time.pomodoro.cyclesBeforeLongBreak = value
                }
            }
        }
    }
}
