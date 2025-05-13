import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    Variants { // Window repeater
        id: sidebarVariants
        model: Quickshell.screens

        PanelWindow { // Window
            id: sidebarRoot
            visible: false
            focusable: true
            property int selectedTab: PersistentStates.sidebar.leftSide.selectedTab
            property bool extend: false
            property real sidebarWidth: sidebarRoot.extend ? Appearance.sizes.sidebarWidthExtended : Appearance.sizes.sidebarWidth

            onVisibleChanged: {
                GlobalStates.sidebarLeftOpenCount += visible ? 1 : -1
            }

            property var modelData

            screen: modelData
            exclusiveZone: 0
            implicitWidth: Appearance.sizes.sidebarWidthExtended
            WlrLayershell.namespace: "quickshell:sidebarLeft"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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
                active: false
                onCleared: () => {
                    if (!active) sidebarRoot.visible = false
                }
            }

            Connections {
                target: sidebarRoot
                function onVisibleChanged() {
                    delayedGrabTimer.start()
                    swipeView.children[0].children[0].children[sidebarRoot.selectedTab].forceActiveFocus()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    grab.active = sidebarRoot.visible
                }
            }

            // Background
            Rectangle {
                id: sidebarLeftBackground

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Appearance.sizes.hyprlandGapsOut
                anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
                width: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
                focus: sidebarRoot.visible

                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                Keys.onPressed: (event) => {
                    // console.log("Key pressed: " + event.key)
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.visible = false;
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", Math.min(sidebarRoot.selectedTab + 1, root.tabButtonList.length - 1))
                        } 
                        else if (event.key === Qt.Key_PageUp) {
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", Math.max(sidebarRoot.selectedTab - 1, 0))
                        }
                        else if (event.key === Qt.Key_Tab) {
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", (sidebarRoot.selectedTab + 1) % root.tabButtonList.length);
                        }
                        else if (event.key === Qt.Key_Backtab) {
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", (sidebarRoot.selectedTab - 1 + root.tabButtonList.length) % root.tabButtonList.length);
                        }
                        else if (event.key === Qt.Key_O) {
                            sidebarRoot.extend = !sidebarRoot.extend;
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
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", currentIndex)
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: sidebarRoot.selectedTab
                        onCurrentIndexChanged: {
                            tabBar.enableIndicatorAnimation = true
                            PersistentStateManager.setState("sidebar.leftSide.selectedTab", currentIndex)
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

            // Shadow
            DropShadow {
                anchors.fill: sidebarLeftBackground
                horizontalOffset: 0
                verticalOffset: 2
                radius: Appearance.sizes.elevationMargin
                samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: Appearance.colors.colShadow
                source: sidebarLeftBackground
            }

        }

    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }

        function close(): void {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                }
            }
        }

        function open(): void {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"

        onPressed: {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: "Opens left sidebar on press"

        onPressed: {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = true;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: "Closes left sidebar on press"

        onPressed: {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                }
            }
        }
    }

}
