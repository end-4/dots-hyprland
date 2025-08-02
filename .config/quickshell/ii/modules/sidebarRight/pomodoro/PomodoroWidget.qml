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
                    spacing: 18

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.timeFormattedPomodoro()
                        font.pixelSize: 50
                        color: Appearance.m3colors.m3onSurface
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        DialogButton {
                            buttonText: Pomodoro.isPomodoroRunning ? Translation.tr("Pause") : Translation.tr("Start")
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 35
                            font.pixelSize: Appearance.font.pixelSize.larger
                            onClicked: Pomodoro.togglePomodoro()
                            background: Rectangle {
                                color: Appearance.m3colors.m3onSecondary
                                radius: Appearance.rounding.normal
                                border.color: Appearance.m3colors.m3outline
                                border.width: 1
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Pomodoro.isPomodoroBreak ? Translation.tr("Break time") : Translation.tr("Focus time")
                            font.pixelSize: Appearance.font.pixelSize.largest
                            color: Appearance.m3colors.m3onSurface
                        }

                        DialogButton {
                            buttonText: Translation.tr("Reset")
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 35
                            font.pixelSize: Appearance.font.pixelSize.larger
                            onClicked: Pomodoro.pomodoroReset()
                            background: Rectangle {
                                color: Appearance.m3colors.m3onError
                                radius: Appearance.rounding.normal
                                border.color: Appearance.m3colors.m3outline
                                border.width: 1
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        StyledText {
                            text: Translation.tr("Focus Duration: %1 min").arg(Pomodoro.pomodoroWorkTime / 60)
                            color: Appearance.m3colors.m3onSurface
                        }
                        Slider {
                            id: workTimeSlider
                            Layout.fillWidth: true
                            from: 5
                            to: 120
                            stepSize: 1
                            value: Pomodoro.pomodoroWorkTime / 60
                            onValueChanged: Pomodoro.pomodoroWorkTime = value * 60
                            handle: Rectangle {
                                x: workTimeSlider.leftPadding + workTimeSlider.visualPosition * (workTimeSlider.availableWidth - width)
                                y: workTimeSlider.topPadding + (workTimeSlider.availableHeight - height) / 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: Appearance.m3colors.m3onSecondary
                                border.color: Appearance.m3colors.m3outline
                            }
                        }

                        StyledText {
                            text: Translation.tr("Break Duration: %1 min").arg(Pomodoro.pomodoroBreakTime / 60)
                            color: Appearance.m3colors.m3onSurface
                        }
                        Slider {
                            id: breakTimeSlider
                            Layout.fillWidth: true
                            from: 1
                            to: 60
                            stepSize: 1
                            value: Pomodoro.pomodoroBreakTime / 60
                            onValueChanged: Pomodoro.pomodoroBreakTime = value * 60
                            handle: Rectangle {
                                x: breakTimeSlider.leftPadding + breakTimeSlider.visualPosition * (breakTimeSlider.availableWidth - width)
                                y: breakTimeSlider.topPadding + (breakTimeSlider.availableHeight - height) / 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: Appearance.m3colors.m3onSecondary
                                border.color: Appearance.m3colors.m3outline
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
                        text: Pomodoro.timeFormattedStopwatch()
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
                            font.pixelSize: Appearance.font.pixelSize.largest
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

    // + FAB
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }
    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins

        onClicked: {
            if (currentTab === 0) {
                Pomodoro.togglePomodoro()
            } else {
                Pomodoro.toggleStopwatch()
            }
        }

        contentItem: MaterialSymbol {
            text: (currentTab === 0 && Pomodoro.isPomodoroRunning) || (currentTab === 1 && Pomodoro.isStopwatchRunning) ? "pause" : "play_arrow"
            horizontalAlignment: Text.AlignHCenter
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.m3colors.m3onPrimaryContainer
        }
    }
}