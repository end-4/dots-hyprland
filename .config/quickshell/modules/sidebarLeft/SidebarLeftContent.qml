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
    id: root
    required property var scopeRoot
    anchors.fill: parent
    property var tabButtonList: [
        ...(Config.options.policies.ai !== 0 ? [{"icon": "neurology", "name": qsTr("Intelligence")}] : []),
        {"icon": "translate", "name": qsTr("Translator")},
        ...(Config.options.policies.weeb === 1 ? [{"icon": "bookmark_heart", "name": qsTr("Anime")}] : [])
    ]
    property int selectedTab: 0

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabButtonList.length - 1)
                event.accepted = true;
            } 
            else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0)
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Tab) {
                root.selectedTab = (root.selectedTab + 1) % root.tabButtonList.length;
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Backtab) {
                root.selectedTab = (root.selectedTab - 1 + root.tabButtonList.length) % root.tabButtonList.length;
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
            tabButtonList: root.tabButtonList
            externalTrackedTab: root.selectedTab
            function onCurrentIndexChanged(currentIndex) {
                root.selectedTab = currentIndex
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
                root.selectedTab = currentIndex
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

            contentChildren: [
                ...(Config.options.policies.ai !== 0 ? [aiChat.createObject()] : []),
                translator.createObject(),
                ...(Config.options.policies.weeb === 0 ? [] : [anime.createObject()])
            ]
        }

        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {
            id: anime
            Anime {}
        }
        
    }
}