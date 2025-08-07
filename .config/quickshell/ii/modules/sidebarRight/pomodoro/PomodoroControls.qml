import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import "../quickToggles/"

Item {
    id: pomodoroControlsRoot
    Layout.fillWidth: true
    
    ContentSection {
        anchors.centerIn: parent

        ColumnLayout {
            
            Layout.fillWidth: true
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                MaterialSymbol {
                    text: Config.pomodoroIsWorking ? "build" : "coffee"
                    
                    Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                StyledText {
                    text: Config.formatTime(Config.pomodoroTimeLeft)
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            QuickToggleButton {
                Layout.alignment: Qt.AlignHCenter
                colBackground: Appearance.colors.colLayer1 // Cor para estado inativo
                colBackgroundToggled: Appearance.m3colors.m3primary // Cor para estado ativo
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                buttonIcon: Config.pomodoroRunning ? "pause" : "play_arrow"
                toggled: Config.pomodoroRunning
                onClicked: {
                    if (Config.pomodoroRunning) {
                        Config.pausePomodoro();
                    } else {
                        Config.startPomodoro();
                    }
                }
                StyledToolTip {
                    content: Config.pomodoroRunning ? "Pausar Pomodoro" : "Iniciar Pomodoro"
                }
            }

            ButtonGroup {
                Layout.fillWidth: true
                spacing: 5
                color: Appearance.colors.colLayer1
                QuickToggleButton {
                    Layout.fillWidth: true
                    buttonIcon: "restart_alt"
                    onClicked: {
                        Config.resetPomodoro();
                    }
                    StyledToolTip {
                        content: "Resetar Pomodoro"
                    }
                }

                QuickToggleButton {
                    Layout.fillWidth: true
                    buttonIcon: "skip_next"
                    onClicked: {
                        Config.skipPomodoro();
                    }
                    StyledToolTip {
                        content: "Pular Ciclo"
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5

                MaterialSymbol {
                    text: "recycling"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: Config.pomodoroSessions
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
