import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    
    Loader {
        id: crosshairLoader
        active: GlobalStates.crosshairOpen
        sourceComponent: PanelWindow {
            id: crosshairWindow
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:crosshair"
            WlrLayershell.layer: WlrLayer.Overlay
            visible: true
            color: "transparent"

            mask: Region { // Crosshair should not block mouse input
                item: null
            }

            implicitWidth: crosshairContent.implicitWidth
            implicitHeight: crosshairContent.implicitHeight

            CrosshairContent {
                id: crosshairContent
                anchors.centerIn: parent
            }
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.crosshairOpen = !GlobalStates.crosshairOpen;
        }
    }

    GlobalShortcut {
        name: "crosshairToggle"
        description: "Toggles crosshair on press"

        onPressed: {
            GlobalStates.crosshairOpen = !GlobalStates.crosshairOpen;
        }
    }
}
