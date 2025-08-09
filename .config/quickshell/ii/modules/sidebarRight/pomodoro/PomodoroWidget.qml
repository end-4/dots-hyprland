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
    id: root
    property int currentTab: 0
    property var tabButtonList: [
        {"name": Translation.tr("Pomodoro"), "icon": "timer_play"},
        {"name": Translation.tr("Stopwatch"), "icon": "timer"}
    ]

    // These are keybinds for stopwatch and pomodoro
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                currentTab = Math.min(currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                currentTab = Math.max(currentTab - 1, 0)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_S) {
            // Toggle start/stop with Space or S key
            if (currentTab === 0) {
                Pomodoro.togglePomodoro()
            } else {
                Pomodoro.toggleStopwatch()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_R) {
            // Reset with R key
            if (currentTab === 0) {
                Pomodoro.pomodoroReset()
            } else {
                Pomodoro.stopwatchReset()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_L) {
            // record Stopwatch lap with L key, regardless of current Tab
            Pomodoro.recordLaps() 
        }
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: Pomodoro.isPomodoroRunning
        repeat: true
        onTriggered: Pomodoro.refreshPomodoro()
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: Pomodoro.isStopwatchRunning
        repeat: true
        onTriggered: Pomodoro.refreshStopwatch()
    }


    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            background: Item {
                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            tabBar.currentIndex = Math.min(tabBar.currentIndex + 1, root.tabButtonList.length - 1)
                        else if (event.angleDelta.y > 0)
                            tabBar.currentIndex = Math.max(tabBar.currentIndex - 1, 0)
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }
            }

            Repeater {
                model: root.tabButtonList
                delegate: SecondaryTabButton {
                    selected: (index == currentTab)
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                }
            }
        }

        Item { // Tab indicator
            id: tabIndicator
            Layout.fillWidth: true
            height: 3
            property bool enableIndicatorAnimation: false
            Connections {
                target: root
                function onCurrentTabChanged() {
                    tabIndicator.enableIndicatorAnimation = true
                }
            }

            Rectangle {
                id: indicator
                property int tabCount: root.tabButtonList.length
                property real fullTabSize: root.width / tabCount;
                property real targetWidth: tabBar.contentItem.children[0].children[tabBar.currentIndex].tabContentWidth

                implicitWidth: targetWidth
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                x: tabBar.currentIndex * fullTabSize + (fullTabSize - targetWidth) / 2

                color: Appearance.colors.colPrimary
                radius: Appearance.rounding.full

                Behavior on x {
                    enabled: tabIndicator.enableIndicatorAnimation
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on implicitWidth {
                    enabled: tabIndicator.enableIndicatorAnimation
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }
        }

        Rectangle { // Tabbar bottom border
            id: tabBarBottomBorder
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOutlineVariant
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            currentIndex: currentTab
            onCurrentIndexChanged: {
                tabIndicator.enableIndicatorAnimation = true
                currentTab = currentIndex
            }

            // Pomodoro Timer Tab
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
                                    text: Pomodoro.isPomodoroRunning ? Translation.tr("Pause") : Translation.tr("Start")
                                    color: Appearance.colors.colSecondary
                                }
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.togglePomodoro()
                                colBackground: Appearance.colors.colSecondaryContainer
                                colBackgroundHover: Appearance.colors.colSecondaryContainer
                            }

                            RippleButton {
                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Translation.tr("Reset")
                                    color: Appearance.colors.colSecondary
                                }
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.pomodoroReset()
                                colBackground: Appearance.m3colors.m3onError
                                colBackgroundHover: Appearance.m3colors.m3onError
                            }
                        }
                    }

                    // The SpinBoxes for adjusting duration
                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        uniformCellWidths: true
                        columnSpacing: 20
                        rowSpacing: 6

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

            // Stopwatch Tab
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
                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Pomodoro.isStopwatchRunning ? Translation.tr("Pause") : Pomodoro.stopwatchTime === 0 ? Translation.tr("Start") : Translation.tr("Resume")
                                    color: Appearance.colors.colSecondary
                                }
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.toggleStopwatch()
                                colBackground: Appearance.colors.colSecondaryContainer
                                colBackgroundHover: Appearance.colors.colSecondaryContainer
                            }

                            RippleButton {
                                contentItem: StyledText {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Pomodoro.isStopwatchRunning ? Translation.tr("Lap") : Translation.tr("Reset")
                                    color: Appearance.colors.colSecondary
                                }
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.stopwatchResetOrLaps()
                                colBackground: Appearance.m3colors.m3onError
                                colBackgroundHover: Appearance.m3colors.m3onError
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
                                        if (lapItem.index != Pomodoro.stopwatchLaps.length - 1) {  // except first lap
                                            let lapTime = lapItem.modelData - Pomodoro.stopwatchLaps[lapItem.index + 1]
                                            let _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                                            let totalSeconds = Math.floor(lapTime) / 100
                                            let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                                            let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                                            return `+${minutes == "00" ? "" : minutes + ":"}${seconds}.${_10ms}`
                                        } else {
                                            return ``  // Nothing for first lap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
