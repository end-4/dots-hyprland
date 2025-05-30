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

Scope { // Scope
    id: root
    property int sidebarPadding: 15
    property var tabButtonList: [{"icon": "neurology", "name": qsTr("Intelligence")}, {"icon": "bookmark_heart", "name": qsTr("Anime")}]

    Loader {
        id: sidebarLoader
        active: GlobalStates.sidebarLeftOpen
        
        PanelWindow { // Window
            id: sidebarRoot
            visible: GlobalStates.sidebarLeftOpen
            
            property int selectedTab: 0
            property bool extend: false
            property bool pin: false
            property real sidebarWidth: sidebarRoot.extend ? Appearance.sizes.sidebarWidthExtended : Appearance.sizes.sidebarWidth

            function hide() {
                GlobalStates.sidebarLeftOpen = false
            }

            exclusiveZone: sidebarRoot.pin ? sidebarWidth : 0
            implicitWidth: Appearance.sizes.sidebarWidthExtended + Appearance.sizes.elevationMargin
            WlrLayershell.namespace: "quickshell:sidebarLeft"
            // Hyprland 0.49: OnDemand is Exclusive, Exclusive just breaks click-outside-to-close
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
            }

            mask: Region {
                item: sidebarLeftBackground
            }

            HyprlandFocusGrab { // Click outside to close
                id: grab
                windows: [ sidebarRoot ]
                active: sidebarRoot.visible && !sidebarRoot.pin
                onActiveChanged: { // Focus the selected tab
                    if (active) swipeView.currentItem.forceActiveFocus()
                }
                onCleared: () => {
                    if (!active) sidebarRoot.hide()
                }
            }

            // Background
            StyledRectangularShadow {
                target: sidebarLeftBackground
            }
            Rectangle {
                id: sidebarLeftBackground

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Appearance.sizes.hyprlandGapsOut
                anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
                width: sidebarRoot.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
                focus: sidebarRoot.visible

                Behavior on width {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Keys.onPressed: (event) => {
                    // console.log("Key pressed: " + event.key)
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.hide();
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            sidebarRoot.selectedTab = Math.min(sidebarRoot.selectedTab + 1, root.tabButtonList.length - 1)
                        } 
                        else if (event.key === Qt.Key_PageUp) {
                            sidebarRoot.selectedTab = Math.max(sidebarRoot.selectedTab - 1, 0)
                        }
                        else if (event.key === Qt.Key_Tab) {
                            sidebarRoot.selectedTab = (sidebarRoot.selectedTab + 1) % root.tabButtonList.length;
                        }
                        else if (event.key === Qt.Key_Backtab) {
                            sidebarRoot.selectedTab = (sidebarRoot.selectedTab - 1 + root.tabButtonList.length) % root.tabButtonList.length;
                        }
                        else if (event.key === Qt.Key_O) {
                            sidebarRoot.extend = !sidebarRoot.extend;
                        }
                        else if (event.key === Qt.Key_P) {
                            sidebarRoot.pin = !sidebarRoot.pin;
                        }
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sidebarPadding
                    
                    spacing: sidebarPadding

                    PrimaryTabBar { // Tab strip
                        id: tabBar
                        tabButtonList: root.tabButtonList
                        externalTrackedTab: sidebarRoot.selectedTab
                        function onCurrentIndexChanged(currentIndex) {
                            sidebarRoot.selectedTab = currentIndex
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
                            sidebarRoot.selectedTab = currentIndex
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

                        AiChat {
                            panelWindow: sidebarRoot
                        }
                        Anime {
                            panelWindow: sidebarRoot
                        }
                    }
                    
                }
            }

        }
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
        }

        function close(): void {
            GlobalStates.sidebarLeftOpen = false
        }

        function open(): void {
            GlobalStates.sidebarLeftOpen = true
        }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: qsTr("Toggles left sidebar on press")

        onPressed: {
            GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: qsTr("Opens left sidebar on press")

        onPressed: {
            GlobalStates.sidebarLeftOpen = true;
        }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: qsTr("Closes left sidebar on press")

        onPressed: {
            GlobalStates.sidebarLeftOpen = false;
        }
    }

}
