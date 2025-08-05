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
    property int lapsListItemPadding: 8
    property int lapsListItemSpacing: 5


    // These are keybinds, make sure to change them.
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                currentTab = Math.min(currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                currentTab = Math.max(currentTab - 1, 0)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Space && !showDialog) {
            // Toggle start/stop with Space key
            if (currentTab === 0) {
                Pomodoro.togglePomodoro()
            } else {
                Pomodoro.toggleStopwatch()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_R && !showDialog) {
            // Reset with R key
            if (currentTab === 0) {
                Pomodoro.pomodoroReset()
            } else {
                Pomodoro.stopwatchReset()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape && showDialog) {
            showDialog = false
            event.accepted = true
        }
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: Config.options.time.pomodoro.running
        repeat: true
        onTriggered: Pomodoro.tickSecond()
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: Pomodoro.isStopwatchRunning
        repeat: true
        onTriggered: Pomodoro.tick10ms()
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
                property real fullTabSize: root.width / tabCount
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
                                let pomodoroTotalTime = Pomodoro.isPomodoroBreak ? Pomodoro.pomodoroBreakTime : Pomodoro.pomodoroFocusTime
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
                                    text: Pomodoro.isPomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
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
                                    text: Pomodoro.isPomodoroRunning ? Translation.tr("Stop") : Translation.tr("Start")
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
                    ColumnLayout {
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            StyledText {
                                id: focusTextBox
                                Layout.leftMargin: focusSpinBox.implicitWidth / 2 - 7
                                text: Translation.tr("Focus")
                            }
                            StyledText {
                                Layout.leftMargin: breakSpinBox.implicitWidth / 2 + 10
                                text: Translation.tr("Break")
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            ConfigSpinBox {
                                id: focusSpinBox
                                spacing: 0
                                Layout.leftMargin: 0
                                Layout.rightMargin: 0
                                value: Config.options.time.pomodoro.focus / 60
                                onValueChanged: {
                                    Config.options.time.pomodoro.focus = value * 60
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
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            StyledText {
                                Layout.leftMargin: focusSpinBox.implicitWidth / 2 - 6
                                text: Translation.tr("Cycle")
                            }
                            StyledText {
                                Layout.leftMargin: breakSpinBox.implicitWidth / 2
                                text: Translation.tr("Long break")
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

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
            }

            // Stopwatch Tab
            Item {
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 40
                        // The Stopwatch circle
                        CircularProgress {
                            Layout.alignment: Qt.AlignHCenter
                            lineWidth: 7
                            gapAngle: Math.PI / 18
                            value: {
                                return Pomodoro.stopwatchTime % 6000 / 6000  // The seconds in percent
                            }
                            size: 125
                            primaryColor: Math.floor(Pomodoro.stopwatchTime / 6000) % 2 ? Appearance.colors.colSecondaryContainer : Appearance.m3colors.m3onSecondaryContainer
                            secondaryColor: Math.floor(Pomodoro.stopwatchTime / 6000) % 2 ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colSecondaryContainer
                            enableAnimation: false  // The animation seems weird after each cycle

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        let totalSeconds = Math.floor(Pomodoro.stopwatchTime) / 100
                                        let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                                        let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                                        return `${minutes}:${seconds}`
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.hugeass + 4
                                    color: Appearance.m3colors.m3onSurface
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        return (Math.floor(Pomodoro.stopwatchTime) % 100).toString().padStart(2, '0')
                                    }
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
                                    text: Pomodoro.isStopwatchRunning ? Translation.tr("Stop") : Translation.tr("Start")
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
                                onClicked: Pomodoro.stopwatchReset()
                                colBackground: Appearance.m3colors.m3onError
                                colBackgroundHover: Appearance.m3colors.m3onError
                            }
                        }
                    }

                    StyledListView {
                        id: lapsList
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        spacing: lapsListItemSpacing
                        clip: true
                        model: Pomodoro.stopwatchLaps

                        delegate: Rectangle {
                            width: lapsList.width
                            implicitHeight: lapsContentText.implicitHeight + lapsListItemPadding
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.small

                            StyledText {
                                id: lapsContentText
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                leftPadding: lapsListItemPadding
                                rightPadding: lapsListItemPadding
                                topPadding: lapsListItemPadding / 2
                                bottomPadding: lapsListItemPadding / 2
                                font.pixelSize: Appearance.font.pixelSize.normal

                                text: {
                                    let lapIndex = index + 1
                                    let lapTime = modelData
                                    // if (index > 0) {
                                        // lapTime = modelData - Pomodoro.stopwatchLaps[index - 1]
                                    // }
                                    let _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                                    let totalSeconds = Math.floor(lapTime) / 100
                                    let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                                    let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                                    return `${minutes}:${seconds}.${_10ms}`
                                }
                            }

                            StyledText {
                                id: lapsDiffText
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                leftPadding: lapsListItemPadding
                                rightPadding: lapsListItemPadding * 2
                                topPadding: lapsListItemPadding / 2
                                bottomPadding: lapsListItemPadding / 2
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colPrimary

                                text: {
                                    let lapTime = modelData
                                    if (index != Pomodoro.stopwatchLaps.length - 1) {  // except first lap
                                        lapTime = modelData - Pomodoro.stopwatchLaps[index + 1]
                                        let _10ms = (Math.floor(lapTime) % 100).toString().padStart(2, '0')
                                        let totalSeconds = Math.floor(lapTime) / 100
                                        let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                                        let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                                        return `+${minutes}:${seconds}.${_10ms}`
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
