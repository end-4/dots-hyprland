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

    // Minutes or seconds of the timer, editable for the plain timer
    component TimeField: StyledTextInput {
        id: field
        property int value
        property int step // Seconds per scroll step
        readOnly: TimerService.pomodoroEnabled || TimerService.pomodoroRunning
        validator: RegularExpressionValidator { regularExpression: /[0-9]{0,3}/ }
        text: value.toString().padStart(2, '0')
        font.pixelSize: 40
        color: Appearance.m3colors.m3onSurface

        onActiveFocusChanged: if (activeFocus) selectAll()
        onEditingFinished: {
            const seconds = Number(minutesField.text) * 60 + Number(secondsField.text);
            if (seconds > 0) TimerService.setTimerDuration(seconds);
            text = Qt.binding(() => value.toString().padStart(2, '0'));
            focus = false;
        }

        MouseArea { // Click always selects the whole field
            anchors.fill: parent
            enabled: !field.readOnly
            cursorShape: Qt.IBeamCursor
            onPressed: {
                field.forceActiveFocus();
                field.selectAll();
            }
            onWheel: event => TimerService.setTimerDuration(TimerService.timerDuration + (event.angleDelta.y > 0 ? field.step : -field.step))
        }
    }

    MouseArea { // Clicking outside the time fields finishes editing
        anchors.fill: parent
        onPressed: root.forceActiveFocus()
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    TimeField {
                        id: minutesField
                        value: Math.floor(TimerService.pomodoroSecondsLeft / 60)
                        step: 60
                        KeyNavigation.tab: secondsField
                    }
                    StyledText {
                        text: ":"
                        font.pixelSize: 40
                        color: Appearance.m3colors.m3onSurface
                    }
                    TimeField {
                        id: secondsField
                        value: Math.floor(TimerService.pomodoroSecondsLeft % 60)
                        step: 1
                    }
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: !TimerService.pomodoroEnabled ? (TimerService.pomodoroRunning ? Translation.tr("Timer") : Translation.tr("Scroll to edit")) : TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            Rectangle {
                visible: TimerService.pomodoroEnabled
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
                    text: TimerService.pomodoroRunning ? Translation.tr("Pause") : (TimerService.pomodoroSecondsLeft === TimerService.pomodoroLapDuration) ? Translation.tr("Start") : Translation.tr("Resume")
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

            RippleButton {
                implicitHeight: 35
                implicitWidth: 35
                buttonRadius: Appearance.rounding.full
                toggled: TimerService.pomodoroEnabled
                onClicked: TimerService.setPomodoroEnabled(!TimerService.pomodoroEnabled)

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: "search_activity"
                    iconSize: Appearance.font.pixelSize.larger
                    color: TimerService.pomodoroEnabled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                }

                StyledToolTip {
                    text: Translation.tr("Pomodoro")
                }
            }
        }
    }
}
