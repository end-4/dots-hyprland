import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./calendar"
import "./notifications"
import "./todo"
import "./volumeMixer"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    property int currentTab: 0
    property var tabButtonList: [{"icon": "notifications", "name": "Notifications"}, {"icon": "volume_up", "name": "Volume mixer"}]

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
            if (event.key === Qt.Key_PageDown) {
                root.currentTab = Math.min(root.currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                root.currentTab = Math.max(root.currentTab - 1, 0)
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.margins: 5
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
                delegate: PrimaryTabButton {
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
                color: Appearance.m3colors.m3primary
                radius: Appearance.rounding.full
                z: 2

                anchors.fill: parent
                anchors.leftMargin: {
                    const tabCount = root.tabButtonList.length
                    const targetWidth = tabBar.contentItem.children[0].children[tabBar.currentIndex].tabContentWidth
                    const fullTabSize = tabBar.width / tabCount;
                    return fullTabSize * currentTab + (fullTabSize - targetWidth) / 2;
                }
                anchors.rightMargin: {
                    const tabCount = root.tabButtonList.length
                    const targetWidth = tabBar.contentItem.children[0].children[tabBar.currentIndex].tabContentWidth
                    const fullTabSize = tabBar.width / tabCount;
                    return fullTabSize * (tabCount - currentTab - 1) + (fullTabSize - targetWidth) / 2;
                }
                Behavior on anchors.leftMargin { 
                    enabled: tabIndicator.enableIndicatorAnimation
                    SmoothedAnimation {
                        velocity: Appearance.animation.positionShift.velocity
                    } 
                }
                Behavior on anchors.rightMargin { 
                    enabled: tabIndicator.enableIndicatorAnimation
                    SmoothedAnimation {
                        velocity: Appearance.animation.positionShift.velocity
                    } 
                }
                
            }
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentTab
            onCurrentIndexChanged: currentTab = currentIndex

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            NotificationList {}
            VolumeMixer {}
        }
    }
}