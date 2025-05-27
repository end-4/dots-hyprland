import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "./quickToggles/"
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

Scope {
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 15

    PanelWindow {
        id: sidebarRoot
        visible: GlobalStates.sidebarRightOpen

        function hide() {
            GlobalStates.sidebarRightOpen = false
        }

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
            active: GlobalStates.sidebarRightOpen
            onCleared: () => {
                if (!active) sidebarRoot.hide()
            }
        }

        Loader {
            id: sidebarContentLoader
            active: GlobalStates.sidebarRightOpen
            anchors.centerIn: parent
            width: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
            
            sourceComponent: Item {
                implicitHeight: sidebarRightBackground.implicitHeight
                implicitWidth: sidebarRightBackground.implicitWidth

                RectangularShadow { // Background shadow
                    anchors.fill: sidebarRightBackground
                    radius: sidebarRightBackground.radius
                    blur: 1.2 * Appearance.sizes.elevationMargin
                    spread: 1
                    color: Appearance.colors.colShadow
                }
                Rectangle {
                    id: sidebarRightBackground

                    anchors.fill: parent
                    implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                    implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
                    color: Appearance.colors.colLayer0
                    radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            sidebarRoot.hide();
                        }
                    }

                    
                    ColumnLayout {
                        spacing: sidebarPadding
                        anchors.fill: parent
                        anchors.margins: sidebarPadding

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
                                text: StringUtils.format(qsTr("Uptime: {0}"), DateTime.uptime)
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

                        ButtonGroup {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5
                            padding: 5
                            color: Appearance.colors.colLayer1

                            NetworkToggle {}
                            BluetoothToggle {}
                            NightLight {}
                            GameMode {}
                            IdleInhibitor {}
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
            }
        }
        

    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            if(GlobalStates.sidebarRightOpen) Notifications.timeoutAll();
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: qsTr("Toggles right sidebar on press")

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            if(GlobalStates.sidebarRightOpen) Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: qsTr("Opens right sidebar on press")

        onPressed: {
            GlobalStates.sidebarRightOpen = true;
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: qsTr("Closes right sidebar on press")

        onPressed: {
            GlobalStates.sidebarRightOpen = false;
        }
    }

}
