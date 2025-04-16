import "root:/modules/common"
import "root:/modules/common/widgets"
import "./calendar"
import "./calendar/calendar_layout.js" as CalendarLayout
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillHeight: false
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    implicitHeight: 343 // TODO NO HARD CODE

    RowLayout {
        id: calendarRow
        anchors.fill: parent
        // width: parent.width - 10 * 2
        height: parent.height - 10 * 2
        spacing: 10
        property int selectedTab: 0
        
        // Navigation rail
        ColumnLayout {
            id: tabBar
            Layout.fillHeight: true
            Layout.fillWidth: false
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

        // Content area
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            // Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            property int realIndex: 0
            property int animationDuration: Appearance.animation.elementDecel.duration * 1.5

            // Calendar
            Component {
                id: calendarWidget

                Item {
                    anchors.centerIn: parent
                    width: calendarColumn.width
                    height: calendarColumn.height
                    property int monthShift: 0
                    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)

                    MouseArea {
                        anchors.fill: parent
                        onWheel: {
                            if (wheel.angleDelta.y > 0) {
                                monthShift--;
                            } else if (wheel.angleDelta.y < 0) {
                                monthShift++;
                            }
                        }
                    }
                    ColumnLayout {
                        id: calendarColumn
                        anchors.centerIn: parent
                        spacing: 5

                        // Calendar header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            spacing: 5
                            CalendarHeaderButton {
                                onClicked: {
                                    monthShift = 0;
                                }
                                content: StyledText {
                                    text: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: false
                            }
                            CalendarHeaderButton {
                                forceCircle: true
                                onClicked: {
                                    monthShift--;
                                }
                                content: MaterialSymbol {
                                    text: "chevron_left"
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                            CalendarHeaderButton {
                                forceCircle: true
                                onClicked: {
                                    monthShift++;
                                }
                                content: MaterialSymbol {
                                    text: "chevron_right"
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        // Week days row
                        RowLayout {
                            id: weekDaysRow
                            Layout.alignment: Qt.AlignHCenter
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

                        // Real week rows
                        Repeater {
                            id: calendarRows
                            model: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
                            delegate: RowLayout {
                                Layout.alignment: Qt.AlignHCenter
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
                Item { // TODO: make behavior on y also act for the item that's switched to
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