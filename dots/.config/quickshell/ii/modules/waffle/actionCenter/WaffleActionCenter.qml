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

        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) barLoader.active = true;
        }
    }

    Loader {
        id: barLoader
        active: GlobalStates.sidebarLeftOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:actionCenter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                bottom: Config.options.waffles.bar.bottom
                top: !Config.options.waffles.bar.bottom
                right: true
            }

            implicitWidth: content.implicitWidth + content.visualMargin * 2
            implicitHeight: content.implicitHeight + content.visualMargin * 2

            HyprlandFocusGrab {
                id: focusGrab
                active: true
                windows: [panelWindow]
                onCleared: content.close();
            }

            Connections {
                target: GlobalStates
                function onSidebarLeftOpenChanged() {
                    if (!GlobalStates.sidebarLeftOpen) content.close();
                }
            }

            ActionCenterContent {
                id: content
                anchors.centerIn: parent

                onClosed: {
                    barLoader.active = false;
                    GlobalStates.sidebarLeftOpen = false;
                }
            }
        }
    }

    function toggleOpen() {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle() {
            root.toggleOpen();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"

        onPressed: root.toggleOpen();
    }
}
