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

    property bool editMode: false

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 0

        // The Pomodoro timer circle
        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            lineWidth: 8
            value: {
                return TimerService.pomodoroLapDuration > 0 ? TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration : 0;
            }
            implicitSize: 200
            enableAnimation: true

            ColumnLayout {
                id: timerCenterLayout
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
                    opacity: timerEditArea.containsMouse ? 0.65 : 1.0
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: editMode ? "expand_less" : "edit"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                    opacity: timerEditArea.containsMouse ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
            }

            // Invisible hit area over the center text – toggles edit mode
            MouseArea {
                id: timerEditArea
                anchors.centerIn: parent
                width: timerCenterLayout.width + 24
                height: timerCenterLayout.height + 16
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: editMode = !editMode
            }

            // Skip button – top-right, above the cycle badge
            Rectangle {
                radius: Appearance.rounding.full
                color: skipMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                anchors {
                    right: parent.right
                    top: parent.top
                }
                implicitWidth: 36
                implicitHeight: 36

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_next"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer2
                }

                MouseArea {
                    id: skipMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TimerService.skipPomodoro()
                }

                StyledToolTip {
                    text: TimerService.pomodoroBreak ? Translation.tr("Skip to focus") : Translation.tr("Skip to break")
                    extraVisibleCondition: skipMouseArea.containsMouse
                }
            }

            // Cycle badge – bottom-right
            Rectangle {
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2

                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                implicitWidth: 36
                implicitHeight: implicitWidth

                StyledText {
                    id: cycleText
                    anchors.centerIn: parent
                    color: Appearance.colors.colOnLayer2
                    text: TimerService.pomodoroCycle + 1
                }
            }
        }

        // The Start/Stop and Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            RippleButton {
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.pomodoroRunning ? Translation.tr("Pause") : (TimerService.pomodoroSecondsLeft === TimerService.focusTime) ? Translation.tr("Start") : Translation.tr("Resume")
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

        // Inline duration editor – toggled by clicking the time display
        ColumnLayout {
            visible: editMode
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 12
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 4

            GridLayout {
                columns: 2
                columnSpacing: 8
                rowSpacing: 6
                Layout.fillWidth: true

                StyledText {
                    text: Translation.tr("Focus (min)")
                    color: Appearance.colors.colOnSecondaryContainer
                    Layout.fillWidth: true
                }
                StyledSpinBox {
                    value: Math.round(Config.options.time.pomodoro.focus / 60)
                    from: 1
                    to: 120
                    onValueChanged: Config.options.time.pomodoro.focus = value * 60
                }

                StyledText {
                    text: Translation.tr("Break (min)")
                    color: Appearance.colors.colOnSecondaryContainer
                    Layout.fillWidth: true
                }
                StyledSpinBox {
                    value: Math.round(Config.options.time.pomodoro.breakTime / 60)
                    from: 0
                    to: 60
                    onValueChanged: Config.options.time.pomodoro.breakTime = value * 60
                }

                StyledText {
                    text: Translation.tr("Long break (min)")
                    color: Appearance.colors.colOnSecondaryContainer
                    Layout.fillWidth: true
                }
                StyledSpinBox {
                    value: Math.round(Config.options.time.pomodoro.longBreak / 60)
                    from: 0
                    to: 60
                    onValueChanged: Config.options.time.pomodoro.longBreak = value * 60
                }

                StyledText {
                    text: Translation.tr("Cycles")
                    color: Appearance.colors.colOnSecondaryContainer
                    Layout.fillWidth: true
                }
                StyledSpinBox {
                    value: Config.options.time.pomodoro.cyclesBeforeLongBreak
                    from: 1
                    to: 10
                    onValueChanged: Config.options.time.pomodoro.cyclesBeforeLongBreak = value
                }
            }
        }
    }
}
