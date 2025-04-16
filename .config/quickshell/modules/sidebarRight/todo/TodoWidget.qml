import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property int currentTab: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            property var tabButtonList: [{"icon": "checklist", "name": "Unfinished"}, {"name": "Done", "icon": "check_circle"}]
            Layout.fillWidth: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            background: Item {
                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0)
                            currentTab = Math.min(currentTab + 1, tabBar.tabButtonList.length - 1)
                        else if (event.angleDelta.y > 0)
                            currentTab = Math.max(currentTab - 1, 0)
                    }
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }
            }

            Repeater {
                model: tabBar.tabButtonList
                delegate: StyledTabButton {
                    selected: (index == currentTab)
                    buttonText: modelData.name
                    // buttonIcon: modelData.icon
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Rectangle {
                property int indicatorPadding: 15
                id: indicator
                color: Appearance.m3colors.m3primary
                height: 3
                radius: Appearance.rounding.full

                width: tabBar.width / tabBar.tabButtonList.length - indicatorPadding * 2
                x: indicatorPadding + tabBar.width / tabBar.tabButtonList.length * currentTab
                z: 2
                Behavior on x { SmoothedAnimation {
                    velocity: Appearance.animation.positionShift.velocity
                } }
                
            }
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            // To Do tab
            TaskList {
                taskList: Todo.list.filter(item => !item.done)
            }
            TaskList {
                taskList: Todo.list.filter(item => item.done)
            }

        }
    }
}