import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledFlickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: settingsColumn.implicitHeight

    function setMinutes(optionName, minutes) {
        Config.options.time.pomodoro[optionName] = Math.max(1, minutes) * 60;
        if (!TimerService.pomodoroRunning) {
            TimerService.resetPomodoro();
        }
    }

    function minutes(optionName) {
        return Math.round(Config.options.time.pomodoro[optionName] / 60);
    }

    function applyPreset(focus, shortBreak, longBreak, cycles) {
        Config.options.time.pomodoro.focus = focus * 60;
        Config.options.time.pomodoro.breakTime = shortBreak * 60;
        Config.options.time.pomodoro.longBreak = longBreak * 60;
        Config.options.time.pomodoro.cyclesBeforeLongBreak = cycles;
        if (!TimerService.pomodoroRunning) {
            TimerService.resetPomodoro();
        }
    }

    function setCycles(cycles) {
        Config.options.time.pomodoro.cyclesBeforeLongBreak = cycles;
        if (!TimerService.pomodoroRunning) {
            TimerService.resetPomodoro();
        }
    }

    ColumnLayout {
        id: settingsColumn
        width: root.width
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 12
            implicitHeight: 108
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "search_activity"
                            iconSize: Appearance.font.pixelSize.hugeass
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            text: Translation.tr("Focus profile")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer2
                        }

                        StyledText {
                            text: `${root.minutes("focus")} / ${root.minutes("breakTime")} / ${root.minutes("longBreak")} min  •  ${Config.options.time.pomodoro.cyclesBeforeLongBreak} cycles`
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ProfileChip {
                        iconName: "search_activity"
                        label: `${root.minutes("focus")}m`
                        color: Appearance.colors.colSecondaryContainer
                        textColor: Appearance.colors.colOnSecondaryContainer
                    }

                    ProfileChip {
                        iconName: "coffee"
                        label: `${root.minutes("breakTime")}m`
                        color: Appearance.colors.colTertiaryContainer
                        textColor: Appearance.colors.colOnTertiaryContainer
                    }

                    ProfileChip {
                        iconName: "spa"
                        label: `${root.minutes("longBreak")}m`
                        color: Appearance.colors.colLayer1
                        textColor: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 3

                        Repeater {
                            model: Config.options.time.pomodoro.cyclesBeforeLongBreak

                            Rectangle {
                                implicitWidth: 7
                                implicitHeight: 7
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colOnLayer2
                                opacity: 0.45
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "timer"
            title: Translation.tr("Pomodoro")

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 6
                uniformCellSizes: true

                PresetButton {
                    label: "25/5"
                    onClicked: root.applyPreset(25, 5, 15, 4)
                }

                PresetButton {
                    label: "50/10"
                    onClicked: root.applyPreset(50, 10, 25, 4)
                }

                PresetButton {
                    label: "15/5"
                    onClicked: root.applyPreset(15, 5, 15, 4)
                }
            }

            PomodoroSpinRow {
                iconName: "search_activity"
                label: Translation.tr("Focus")
                suffix: Translation.tr("min")
                from: 1
                to: 180
                stepSize: 5
                value: root.minutes("focus")
                onValueModified: value => root.setMinutes("focus", value)
            }

            PomodoroSpinRow {
                iconName: "coffee"
                label: Translation.tr("Break")
                suffix: Translation.tr("min")
                from: 1
                to: 60
                stepSize: 1
                value: root.minutes("breakTime")
                onValueModified: value => root.setMinutes("breakTime", value)
            }

            PomodoroSpinRow {
                iconName: "spa"
                label: Translation.tr("Long break")
                suffix: Translation.tr("min")
                from: 1
                to: 120
                stepSize: 5
                value: root.minutes("longBreak")
                onValueModified: value => root.setMinutes("longBreak", value)
            }

            PomodoroSpinRow {
                iconName: "repeat"
                label: Translation.tr("Cycles")
                suffix: ""
                from: 1
                to: 12
                stepSize: 1
                value: Config.options.time.pomodoro.cyclesBeforeLongBreak
                onValueModified: value => root.setCycles(value)
            }
        }

        ContentSection {
            icon: "notifications"
            title: Translation.tr("Alerts")

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "notifications"
                    text: Translation.tr("Notifications")
                    checked: Config.options.time.pomodoro.notifications
                    onCheckedChanged: Config.options.time.pomodoro.notifications = checked
                }

                ConfigSwitch {
                    buttonIcon: "notification_sound"
                    text: Translation.tr("Sound")
                    checked: Config.options.sounds.pomodoro
                    onCheckedChanged: Config.options.sounds.pomodoro = checked
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                onClicked: Audio.playSystemSound("alarm-clock-elapsed")

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialSymbol {
                        text: "play_circle"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer2
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Test sound")
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 4
        }
    }

    component PresetButton: RippleButton {
        id: preset
        property string label

        Layout.fillWidth: true
        implicitHeight: 34
        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active

        contentItem: StyledText {
            anchors.centerIn: parent
            text: preset.label
            horizontalAlignment: Text.AlignHCenter
            font.family: Appearance.font.family.main
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer2
        }
    }

    component ProfileChip: Rectangle {
        property string iconName
        property string label
        property color textColor

        Layout.fillWidth: true
        implicitHeight: 28
        radius: Appearance.rounding.full

        RowLayout {
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: parent.parent.iconName
                iconSize: 14
                color: parent.parent.textColor
            }

            StyledText {
                text: parent.parent.label
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: parent.parent.textColor
            }
        }
    }

    component PomodoroSpinRow: RowLayout {
        id: row

        property string iconName
        property string label
        property string suffix
        property alias value: spinBox.value
        property alias from: spinBox.from
        property alias to: spinBox.to
        property alias stepSize: spinBox.stepSize
        signal valueModified(int value)

        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 10

        MaterialSymbol {
            text: row.iconName
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSecondaryContainer
        }

        StyledText {
            Layout.fillWidth: true
            text: row.label
            color: Appearance.colors.colOnSecondaryContainer
        }

        StyledSpinBox {
            id: spinBox
            Layout.preferredWidth: 96
            stepSize: 1
            onValueModified: row.valueModified(value)
        }

        StyledText {
            Layout.preferredWidth: 24
            text: row.suffix
            color: Appearance.colors.colSubtext
        }
    }
}
