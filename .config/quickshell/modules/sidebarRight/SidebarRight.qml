import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "./quickToggles/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 15

    Variants {
        id: sidebarVariants
        model: Quickshell.screens

        PanelWindow {
            id: sidebarRoot
            visible: false
            focusable: true

            onVisibleChanged: {
                GlobalStates.sidebarRightOpenCount += visible ? 1 : -1
            }

            property var modelData

            screen: modelData
            exclusiveZone: 0
            implicitWidth: sidebarWidth
            WlrLayershell.namespace: "quickshell:sidebarRight"
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
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
                id: sidebarRightBackground

                anchors.centerIn: parent
                width: parent.width - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.visible = false;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sidebarPadding
                    
                    spacing: sidebarPadding

                    RowLayout {
                        Layout.fillHeight: false
                        spacing: 10
                        Layout.margins: 10
                        Layout.topMargin: 5
                        Layout.bottomMargin: 0

                        Item {
                            implicitWidth: distroIcon.width
                            implicitHeight: distroIcon.height
                            CustomIcon {
                                id: distroIcon
                                width: 25
                                height: 25
                                source: SystemInfo.distroIcon
                            }
                            ColorOverlay {
                                anchors.fill: distroIcon
                                source: distroIcon
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            text: `Uptime: ${DateTime.uptime}`
                            textFormat: Text.MarkdownText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QuickToggleButton {
                            toggled: false
                            buttonIcon: "power_settings_new"
                            onClicked: {
                                Hyprland.dispatch("global quickshell:sessionOpen")
                            }
                            StyledToolTip {
                                content: qsTr("Session")
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: false
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1
                        implicitWidth: sidebarQuickControlsRow.implicitWidth + 10
                        implicitHeight: sidebarQuickControlsRow.implicitHeight + 10
                        
                        
                        RowLayout {
                            id: sidebarQuickControlsRow
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5

                            NetworkToggle {}
                            BluetoothToggle {}
                            NightLight {}
                            GameMode {}
                            IdleInhibitor {}
                            
                        }
                    }

                    // Center widget group
                    CenterWidgetGroup {
                        focus: sidebarRoot.visible
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    BottomWidgetGroup {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                    }
                }
            }

            // Shadow
            DropShadow {
                anchors.fill: sidebarRightBackground
                horizontalOffset: 0
                verticalOffset: 2
                radius: Appearance.sizes.elevationMargin
                samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: Appearance.colors.colShadow
                source: sidebarRightBackground
            }

        }

    }

    IpcHandler {
        target: "sidebarRight"

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
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"

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
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"

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
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"

        onPressed: {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = false;
                    if(panelWindow.visible) Notifications.timeoutAll();
                }
            }
        }
    }

}
