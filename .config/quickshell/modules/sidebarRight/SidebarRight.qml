import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./quickToggles/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

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

            property var modelData

            screen: modelData
            exclusiveZone: 0
            width: sidebarWidth
            WlrLayershell.namespace: "quickshell:sidebarRight"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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

                focus: true
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.visible = false;
                        event.accepted = true; // Prevent further propagation of the event
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    height: parent.height - sidebarPadding * 2
                    width: parent.width - sidebarPadding * 2
                    spacing: sidebarPadding

                    RowLayout {
                        Layout.fillHeight: false
                        spacing: 10
                        Layout.margins: 10
                        Layout.bottomMargin: 5

                        CustomIcon {
                            width: 25
                            height: 25
                            source: SystemInfo.distroIcon
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            text: `Uptime: ${DateTime.uptime}`
                            textFormat: Text.MarkdownText
                        }

                        Item {
                            Layout.fillHeight: true
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

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                    }

                    // Calendar
                    BottomWidgetGroup {}
                }
            }

            // Shadow
            DropShadow {
                anchors.fill: sidebarRightBackground
                horizontalOffset: 0
                verticalOffset: 2
                radius: Appearance.sizes.elevationMargin
                samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: Appearance.transparentize(Appearance.m3colors.m3shadow, 0.55)
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
                }
            }
        }
    }

}
