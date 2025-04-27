import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Scope { // Scope
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 15
    property var tabButtonList: [{"icon": "neurology", "name": qsTr("Intelligence")}, {"icon": "flare", "name": qsTr("Waifus")}]

    Variants { // Window repeater
        id: sidebarVariants
        model: Quickshell.screens

        PanelWindow { // Window
            id: sidebarRoot
            visible: false
            focusable: true
            property int currentTab: 0

            onVisibleChanged: {
                GlobalStates.sidebarLeftOpenCount += visible ? 1 : -1
            }

            property var modelData

            screen: modelData
            exclusiveZone: 0
            width: sidebarWidth
            WlrLayershell.namespace: "quickshell:sidebarLeft"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
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

                anchors.centerIn: parent
                width: parent.width - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
                focus: sidebarRoot.visible

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.visible = false;
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        console.log("Control pressed")
                        if (event.key === Qt.Key_PageDown) {
                            sidebarRoot.currentTab = Math.min(sidebarRoot.currentTab + 1, root.tabButtonList.length - 1)
                        } else if (event.key === Qt.Key_PageUp) {
                            sidebarRoot.currentTab = Math.max(sidebarRoot.currentTab - 1, 0)
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
                        externalTrackedTab: sidebarRoot.currentTab
                        function onCurrentIndexChanged(currentIndex) {
                            sidebarRoot.currentTab = currentIndex
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: currentTab
                        onCurrentIndexChanged: {
                            tabBar.enableIndicatorAnimation = true
                            sidebarRoot.currentTab = currentIndex
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: swipeView.width
                                height: swipeView.height
                                radius: Appearance.rounding.small
                            }
                        }

                        Item {}
                        Item {}
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

}
