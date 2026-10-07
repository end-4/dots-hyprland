import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root

    property bool vertical: false
    readonly property color stateColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : Appearance.colors.colSecondaryContainer
    readonly property color stateColorHover: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainerHover : Appearance.colors.colSecondaryContainerHover
    readonly property color stateColorActive: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainerActive : Appearance.colors.colSecondaryContainerActive
    readonly property color stateTextColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnSecondaryContainer

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth - 10 : 104
    implicitHeight: vertical ? 54 : Appearance.sizes.baseBarHeight - 8

    buttonRadius: Appearance.rounding.full
    toggled: TimerService.pomodoroRunning
    colBackground: stateColor
    colBackgroundHover: stateColorHover
    colRipple: stateColorActive
    colBackgroundToggled: stateColor
    colBackgroundToggledHover: stateColorHover
    colRippleToggled: stateColorActive

    function pomodoroTimeText() {
        const minutes = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, "0");
        const seconds = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, "0");
        return `${minutes}:${seconds}`;
    }

    function compactMinutesText() {
        return Math.ceil(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, "0");
    }

    onClicked: {
        Persistent.states.sidebar.bottomGroup.collapsed = false;
        Persistent.states.sidebar.bottomGroup.tab = 2;
        GlobalStates.sidebarRightOpen = true;
    }

    contentItem: Item {
        anchors.fill: parent

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            visible: !root.vertical
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: TimerService.pomodoroBreak ? "coffee" : "search_activity"
                iconSize: Appearance.font.pixelSize.larger
                color: root.stateTextColor
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 48
                horizontalAlignment: Text.AlignHCenter
                text: root.pomodoroTimeText()
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: root.stateTextColor
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: root.vertical
            spacing: 1

            ClippedFilledCircularProgress {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: 28
                lineWidth: 3
                value: TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration
                colPrimary: root.stateTextColor
                colSecondary: root.stateColorHover
                enableAnimation: true

                textMask: Item {
                    width: 28
                    height: 28

                    StyledText {
                        anchors.centerIn: parent
                        text: root.compactMinutesText()
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: TimerService.pomodoroBreak ? "coffee" : "search_activity"
                iconSize: 14
                color: root.stateTextColor
            }
        }
    }

    StyledToolTip {
        text: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Pomodoro")
    }
}
