import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./calendar"
import "./todo"
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
    height: bottomWidgetGroupRow.height

    RowLayout {
        id: bottomWidgetGroupRow
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
                    toggled: bottomWidgetGroupRow.selectedTab == index
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                    onClicked: {
                        bottomWidgetGroupRow.selectedTab = index
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

                CalendarWidget {
                    anchors.centerIn: parent
                }
            }

            // To Do
            Component {
                id: todoWidget
                TodoWidget {
                    anchors.fill: parent
                    anchors.margins: 5
                }
            }

            Connections {
                target: bottomWidgetGroupRow
                function onSelectedTabChanged() {
                    delayedStackSwitch.start()
                    tabStack.realIndex = bottomWidgetGroupRow.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: tabStack.animationDuration / 2
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = bottomWidgetGroupRow.selectedTab
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