import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "calendar_layout.js" as CalendarLayout

Rectangle {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillHeight: false
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    implicitHeight: 300

    RowLayout {
        id: calendarRow
        anchors.fill: parent
        width: parent.width - 10 * 2
        height: parent.height - 10 * 2
        spacing: 10
        property int selectedTab: 0
        
        ColumnLayout {
            id: tabBar
            Layout.fillHeight: true
            Layout.leftMargin: 15
            spacing: 15
            Repeater {
                model: [
                    {"name": "Calendar", "icon": "calendar_month"}, 
                    {"name": "To Do", "icon": "done_outline"} 
                ]
                NavRailButton {
                    toggled: calendarRow.selectedTab == index
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                    onClicked: {
                        calendarRow.selectedTab = index
                    }
                }
            }
        }
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            property int realIndex: 0
            property int animationDuration: Appearance.animation.elementDecel.duration * 1.5

            // Calendar
            Component {
                id: calendarWidget
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        spacing: 5
                        Repeater {
                            model: CalendarLayout.weekDays
                            delegate: CalendarDayButton {
                                day: modelData.day
                                isToday: modelData.today
                                bold: true
                                interactable: false
                            }
                        }
                    }
                    Repeater {
                        model: CalendarLayout.getCalendarLayout(null, true)
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            spacing: 5
                            Repeater {
                                model: modelData
                                delegate: CalendarDayButton {
                                    day: modelData.day
                                    isToday: modelData.today
                                }
                            }
                        }
                    }
                }
            }

            // To Do
            Component {
                id: todoWidget
                Item {
                    anchors.fill: parent
                    // color: "lavender"
                    // radius: Appearance.rounding.small
                    width: 30; height: 30;
                    StyledText {
                        anchors.margins: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: "## To Do\n- Lorem ipsum\n- Dolor shit amet\n\nSigma Ohayo rc1 Pro+ Premium Hippuland hi ask vaxry for pleas fix 123 Billions must lorem ipsum ipsum yesterdays tears are tomorrows coom awawawa"
                        wrapMode: Text.WordWrap
                        textFormat: Text.MarkdownText
                    }
                }
            }

            Connections {
                target: calendarRow
                function onSelectedTabChanged() {
                    delayedStackSwitch.start()
                    tabStack.realIndex = calendarRow.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: tabStack.animationDuration / 2
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = calendarRow.selectedTab
                }
            }

            Repeater {
                model: [
                    { type: "calendar" },
                    { type: "todo" }
                ]
                Item {
                    id: tabItem
                    property int tabIndex: index
                    property string tabType: modelData.type
                    property int animDistance: 5
                    opacity: (tabStack.currentIndex === tabItem.tabIndex && tabStack.realIndex === tabItem.tabIndex) ? 1 : 0
                    y: (tabStack.realIndex === tabItem.tabIndex) ? 0 : (tabStack.realIndex < tabItem.tabIndex) ? animDistance : -animDistance
                    Behavior on opacity { NumberAnimation { duration: tabStack.animationDuration / 2; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: tabStack.animationDuration; easing.type: Easing.OutExpo } }
                    Loader {
                        anchors.fill: parent
                        sourceComponent: (tabType === "calendar") ? calendarWidget : todoWidget
                    }
                }
            }
        }
    }
}