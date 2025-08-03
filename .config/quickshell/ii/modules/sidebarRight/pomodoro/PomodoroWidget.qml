import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property int currentTab: 0
    property var tabButtonList: [
        {"name": Translation.tr("Pomodoro"), "icon": "timer_play"},
        {"name": Translation.tr("Stopwatch"), "icon": "timer"}
    ]
    property bool showDialog: false
    property int dialogMargins: 20
    property int fabSize: 48
    property int fabMargins: 14


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
            // Toggle start/pause with Space key
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
        interval: 1000
        running: Pomodoro.isPomodoroRunning
        repeat: true
        onTriggered: Pomodoro.tickSecond()
    }

    Timer {
        id: stopwatchTimer
        interval: 1000
        running: Pomodoro.isStopwatchRunning
        repeat: true
        onTriggered: {
            Pomodoro.stopwatchTime += 1
        }
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
                            value: {
                                let pomodoroTotalTime = Pomodoro.isPomodoroBreak ? Pomodoro.pomodoroBreakTime : Pomodoro.pomodoroFocusTime
                                return Pomodoro.getPomodoroSecondsLeft / pomodoroTotalTime
                            }
                            size: 125
                            secondaryColor: Appearance.colors.colSecondaryContainer
                            primaryColor: Appearance.m3colors.m3onSecondaryContainer
                            enableAnimation: true

                            ColumnLayout {
                                anchors.centerIn: parent

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
                            spacing: 20

                            RippleButton {
                                buttonText: Pomodoro.isPomodoroRunning ? Translation.tr("Pause") : Translation.tr("Start")
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.togglePomodoro()
                                colBackground: Appearance.m3colors.m3onSecondary
                                colBackgroundHover: Appearance.m3colors.m3onSecondary
                            }

                            RippleButton {
                                buttonText: Translation.tr("Reset")
                                Layout.preferredHeight: 35
                                Layout.preferredWidth: 90
                                font.pixelSize: Appearance.font.pixelSize.larger
                                onClicked: Pomodoro.pomodoroReset()
                                colBackground: Appearance.m3colors.m3onError
                                colBackgroundHover: Appearance.m3colors.m3onError
                            }
                        }
                    }

                    // The sliders for adjusting duration
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        ConfigSpinBox {
                            text: Translation.tr("Focus Duration: ")
                            value: Pomodoro.pomodoroFocusTime / 60
                            onValueChanged: {
                                Pomodoro.pomodoroFocusTime = value * 60
                                Config.options.time.pomodoro.focus = value * 60
                            }
                            Layout.alignment: Qt.AlignCenter
                        }

                        ConfigSpinBox {
                            text: Translation.tr("Break Duration:")
                            value: Pomodoro.pomodoroBreakTime / 60
                            onValueChanged: {
                                Config.options.time.pomodoro.breaktime = value * 60
                                Pomodoro.pomodoroBreakTime = value * 60
                            }
                        }

                        ConfigSpinBox {
                            text: Translation.tr("Long Break Duration:")
                            value: Pomodoro.pomodoroLongBreakTime / 60
                            onValueChanged:{
                                Pomodoro.pomodoroLongBreakTime = value * 60
                                Config.options.time.pomodoro.longbreak = value * 60
                            }
                        }
                    }
                }
            }

            // Stopwatch Tab
            Item {
                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            let totalSeconds = Math.floor(Pomodoro.stopwatchTime) 
                            let hours = Math.floor(totalSeconds / 3600).toString().padStart(2, '0')
                            let minutes = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0')
                            let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                            return `${hours}:${minutes}:${seconds}`
                        }
                        font.pixelSize: 50
                        color: Appearance.m3colors.m3onSurface
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        DialogButton {
                            buttonText: Pomodoro.isStopwatchRunning ? Translation.tr("Pause") : Translation.tr("Start")
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 35
                            font.pixelSize: Appearance.font.pixelSize.larger
                            onClicked: Pomodoro.toggleStopwatch()
                            background: Rectangle {
                                color: Appearance.m3colors.m3onSecondary
                                radius: Appearance.rounding.normal
                                border.color: Appearance.m3colors.m3outline
                                border.width: 1
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("Stopwatch")
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.m3colors.m3onSurface
                        }

                        DialogButton {
                            buttonText: Translation.tr("Reset")
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 35
                            font.pixelSize: Appearance.font.pixelSize.larger
                            onClicked: Pomodoro.stopwatchReset()
                            background: Rectangle {
                                color: Appearance.m3colors.m3onError
                                radius: Appearance.rounding.normal
                                border.color: Appearance.m3colors.m3outline
                                border.width: 1
                            }
                        }
                    }
                }
            }
        }
    }
}
