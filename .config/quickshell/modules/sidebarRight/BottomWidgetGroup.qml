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
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillHeight: false
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    height: bottomWidgetGroupRow.height
    property int selectedTab: 0
    property var tabs: [
        {"type": "calendar", "name": "Calendar", "icon": "calendar_month", "widget": calendarWidget}, 
        {"type": "todo", "name": "To Do", "icon": "done_outline", "widget": todoWidget} 
    ]
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

    RowLayout {
        id: bottomWidgetGroupRow
        anchors.fill: parent 
        height: tabStack.height
        spacing: 10
        
        // Navigation rail
        ColumnLayout {
            id: tabBar
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 15
            spacing: 15
            Repeater {
                model: root.tabs
                NavRailButton {
                    toggled: root.selectedTab == index
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                    onClicked: {
                        root.selectedTab = index
                    }
                }
            }
        }

        // Content area
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            height: tabStack.children[0]?.tabLoader?.implicitHeight // TODO: make this less stupid
            Layout.alignment: Qt.AlignVCenter
            property int realIndex: 0
            property int animationDuration: Appearance.animation.elementDecel.duration * 1.5

            // Switch the tab on halfway of the anim duration
            Connections {
                target: root
                function onSelectedTabChanged() {
                    delayedStackSwitch.start()
                    tabStack.realIndex = root.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: tabStack.animationDuration / 2
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = root.selectedTab
                }
            }

            Repeater {
                model: tabs
                Item { // TODO: make behavior on y also act for the item that's switched to
                    id: tabItem
                    property int tabIndex: index
                    property string tabType: modelData.type
                    property int animDistance: 5
                    property var tabLoader: tabLoader
                    // Opacity: show up only when being animated to
                    opacity: (tabStack.currentIndex === tabItem.tabIndex && tabStack.realIndex === tabItem.tabIndex) ? 1 : 0
                    // Y: starts animating when user selects a different tab
                    y: (tabStack.realIndex === tabItem.tabIndex) ? 0 : (tabStack.realIndex < tabItem.tabIndex) ? animDistance : -animDistance
                    Behavior on opacity { NumberAnimation { duration: tabStack.animationDuration / 2; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: tabStack.animationDuration; easing.type: Easing.OutExpo } }
                    Loader {
                        id: tabLoader
                        anchors.fill: parent
                        sourceComponent: modelData.widget
                    }
                }
            }
        }
    }
}