import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    Connections {
        target: GlobalStates

        function onSidebarRightOpenChanged() {
            if (GlobalStates.sidebarRightOpen) panelLoader.active = true;
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.sidebarRightOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wNotificationCenter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                bottom: true
                top: true
                right: true
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            HyprlandFocusGrab {
                id: focusGrab
                active: true
                windows: [panelWindow]
                onCleared: content.close();
            }

            Connections {
                target: GlobalStates
                function onSidebarRightOpenChanged() {
                    if (!GlobalStates.sidebarRightOpen) content.close();
                }
            }

            NotificationCenterContent {
                id: content
                anchors.fill: parent

                onClosed: {
                    GlobalStates.sidebarRightOpen = false;
                    panelLoader.active = false;
                }
            }
        }
    }

    function toggleOpen() {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle() {
            root.toggleOpen();
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles notification center on press"

        onPressed: root.toggleOpen();
    }
}
