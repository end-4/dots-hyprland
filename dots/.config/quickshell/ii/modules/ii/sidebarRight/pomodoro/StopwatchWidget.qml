import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_S) {
            TimerService.toggleStopwatch();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            TimerService.stopwatchReset();
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            TimerService.stopwatchRecordLap();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 14
            spacing: 8

            MaterialSymbol {
                text: "timer"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.colors.colOnSecondaryContainer
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Translation.tr("Stopwatch")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    topPadding: 12
                }

                StyledText {
                    text: TimerService.stopwatchRunning ? Translation.tr("Running") : Translation.tr("Ready")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }

        Stopwatch {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
