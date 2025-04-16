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
    // implicitHeight: 343 // TODO NO HARD CODE
    height: calendarWidgetRow.height

    RowLayout {
        id: calendarWidgetRow
        anchors.fill: parent 
        height: tabStack.height
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
                    toggled: calendarWidgetRow.selectedTab == index
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                    onClicked: {
                        calendarWidgetRow.selectedTab = index
                    }
                }
            }
        }

        // Content area
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            height: 358 // ???? wtf
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
                    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)

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
                            spacing: 5
                            CalendarHeaderButton {
                                buttonText: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                                tooltipText: (monthShift === 0) ? "" : "Jump to current month"
                                onClicked: {
                                    monthShift = 0;
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
                                contentItem: MaterialSymbol {
                                    text: "chevron_left"
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                            CalendarHeaderButton {
                                forceCircle: true
                                onClicked: {
                                    monthShift++;
                                }
                                contentItem: MaterialSymbol {
                                    text: "chevron_right"
                                    font.pixelSize: Appearance.font.pixelSize.larger
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
                            // model: calendarLayout
                            model: 6
                            delegate: RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.fillHeight: false
                                spacing: 5
                                Repeater {
                                    model: Array(7).fill(modelData)
                                    delegate: CalendarDayButton {
                                        day: calendarLayout[modelData][index].day
                                        isToday: calendarLayout[modelData][index].today
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
                target: calendarWidgetRow
                function onSelectedTabChanged() {
                    delayedStackSwitch.start()
                    tabStack.realIndex = calendarWidgetRow.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: tabStack.animationDuration / 2
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = calendarWidgetRow.selectedTab
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