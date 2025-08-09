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
    id: stopwatchTab
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 20
        }
        spacing: 20

        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false

            RowLayout { // Elapsed
                id: elapsedIndicator
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                StyledText {
                    Layout.preferredWidth: elapsedIndicator.width * 0.6 // Prevent shakiness
                    font.pixelSize: 40
                    color: Appearance.m3colors.m3onSurface
                    text: {
                        let totalSeconds = Math.floor(Pomodoro.stopwatchTime) / 100
                        let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                        let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                        return `${minutes}:${seconds}`
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: 40
                    color: Appearance.colors.colSubtext
                    text: {
                        return `:<sub>${(Math.floor(Pomodoro.stopwatchTime) % 100).toString().padStart(2, '0')}</sub>`
                    }
                }
            }

            // The Start/Stop and Reset buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                RippleButton {
                    Layout.preferredHeight: 35
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.larger

                    onClicked: Pomodoro.toggleStopwatch()

                    colBackground: Pomodoro.isStopwatchRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary 
                    colBackgroundHover: Pomodoro.isStopwatchRunning ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colPrimaryHover 
                    colRipple: Pomodoro.isStopwatchRunning ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colPrimaryActive 

                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        color: Pomodoro.isStopwatchRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                        text: Pomodoro.isStopwatchRunning ? Translation.tr("Pause") : Pomodoro.stopwatchTime === 0 ? Translation.tr("Start") : Translation.tr("Resume")
                    }
                }

                RippleButton {
                    implicitHeight: 35
                    implicitWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.larger

                    onClicked: Pomodoro.stopwatchResetOrLaps()
                    enabled: Pomodoro.stopwatchTime !== 0

                    colBackground: Pomodoro.isStopwatchRunning ? Appearance.colors.colLayer2 : Appearance.colors.colErrorContainer
                    colBackgroundHover: Pomodoro.isStopwatchRunning ? Appearance.colors.colLayer2Hover : Appearance.colors.colErrorContainerHover
                    colRipple: Pomodoro.isStopwatchRunning ? Appearance.colors.colLayer2Active : Appearance.colors.colErrorContainerActive

                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Pomodoro.isStopwatchRunning ? Translation.tr("Lap") : Translation.tr("Reset")
                        color: Pomodoro.isStopwatchRunning ? Appearance.colors.colOnLayer2 : Appearance.colors.colOnErrorContainer
                    }
                }
            }
        }

        // Laps
        StyledListView {
            id: lapsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: lapsListItemSpacing
            clip: true
            popin: true

            model: ScriptModel {
                values: Pomodoro.stopwatchLaps
            }

            delegate: Rectangle {
                id: lapItem
                required property int index
                required property var modelData
                property var horizontalPadding: 10
                property var verticalPadding: 6
                width: lapsList.width
                implicitHeight: lapRow.implicitHeight + verticalPadding * 2
                implicitWidth: lapRow.implicitWidth + horizontalPadding * 2
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.small

                RowLayout {
                    id: lapRow
                    anchors {
                        fill: parent
                        leftMargin: lapItem.horizontalPadding
                        rightMargin: lapItem.horizontalPadding
                        topMargin: lapItem.verticalPadding
                        bottomMargin: lapItem.verticalPadding
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: `${Pomodoro.stopwatchLaps.length - lapItem.index}.`
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: {
                            let lapTime = lapItem.modelData
                            let _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                            let totalSeconds = Math.floor(lapTime) / 100
                            let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                            let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                            return `${minutes}:${seconds}.${_10ms}`
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colPrimary
                        text: {
                            let lastTime = (lapItem.index != Pomodoro.stopwatchLaps.length - 1) ? Pomodoro.stopwatchLaps[lapItem.index + 1] : 0
                            let lapTime = lapItem.modelData - lastTime
                            let _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                            let totalSeconds = Math.floor(lapTime) / 100
                            let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                            let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                            return `+${minutes == "00" ? "" : minutes + ":"}${seconds}.${_10ms}`
                        }
                    }
                }
            }
        }
    }
}