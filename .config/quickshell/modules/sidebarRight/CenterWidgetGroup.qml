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
    property var tabButtonList: [{"icon": "notifications", "name": qsTr("Notifications")}, {"icon": "volume_up", "name": qsTr("Volume mixer")}]

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
            if (event.key === Qt.Key_PageDown) {
                root.currentTab = Math.min(root.currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                root.currentTab = Math.max(root.currentTab - 1, 0)
            }
            event.accepted = true;
        }
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_Tab) {
                root.currentTab = (root.currentTab + 1) % root.tabButtonList.length;
            } else if (event.key === Qt.Key_Backtab) {
                root.currentTab = (root.currentTab - 1 + root.tabButtonList.length) % root.tabButtonList.length;
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.margins: 5
        anchors.fill: parent
        spacing: 0

        PrimaryTabBar {
            id: tabBar
            tabButtonList: root.tabButtonList
            externalTrackedTab: root.currentTab
            function onCurrentIndexChanged(currentIndex) {
                root.currentTab = currentIndex
            }
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentTab
            onCurrentIndexChanged: {
                tabBar.enableIndicatorAnimation = true
                root.currentTab = currentIndex
            }

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