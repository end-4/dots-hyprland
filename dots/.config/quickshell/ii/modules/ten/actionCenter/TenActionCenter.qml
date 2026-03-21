pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

Scope {
    id: root

    IpcHandler {
        target: "actionCenter"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        }
    }

    GlobalShortcut {
        name: "actionCenterToggle"
        description: "Toggles action center"

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
        }
    }
}
