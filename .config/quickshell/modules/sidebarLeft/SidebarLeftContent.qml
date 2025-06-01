import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: sidebarLeftBackground
    required property var scopeRoot
    anchors.fill: parent

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                scopeRoot.selectedTab = Math.min(scopeRoot.selectedTab + 1, scopeRoot.tabButtonList.length - 1)
                event.accepted = true;
            } 
            else if (event.key === Qt.Key_PageUp) {
                scopeRoot.selectedTab = Math.max(scopeRoot.selectedTab - 1, 0)
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Tab) {
                scopeRoot.selectedTab = (scopeRoot.selectedTab + 1) % scopeRoot.tabButtonList.length;
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Backtab) {
                scopeRoot.selectedTab = (scopeRoot.selectedTab - 1 + scopeRoot.tabButtonList.length) % scopeRoot.tabButtonList.length;
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: sidebarPadding
        
        spacing: sidebarPadding

        PrimaryTabBar { // Tab strip
            id: tabBar
            tabButtonList: scopeRoot.tabButtonList
            externalTrackedTab: scopeRoot.selectedTab
            function onCurrentIndexChanged(currentIndex) {
                scopeRoot.selectedTab = currentIndex
            }
        }

        SwipeView { // Content pages
            id: swipeView
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            
            currentIndex: tabBar.externalTrackedTab
            onCurrentIndexChanged: {
                tabBar.enableIndicatorAnimation = true
                scopeRoot.selectedTab = currentIndex
            }

            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            AiChat {}
            Anime {}
        }
        
    }
}