import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var scopeRoot
    anchors.fill: parent
    property var tabButtonList: [
        ...(Config.options.policies.ai !== 0 ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        {"icon": "translate", "name": Translation.tr("Translator")},
        ...(Config.options.policies.weeb === 1 ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int selectedTab: 0

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Rectangle {
        id: sidebarLeftBackground
        anchors.fill: parent
        color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, Config.options.appearance.sidebarTransparency.enable ? Config.options.appearance.sidebarTransparency.transparency : 1.0)
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ScrollView {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: parent.width
                
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
}