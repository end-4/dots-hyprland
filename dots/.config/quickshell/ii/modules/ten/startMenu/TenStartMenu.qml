pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

Scope {
    id: root

    IpcHandler {
        target: "startMenu"

        function toggle(): void {
            GlobalStates.searchOpen = !GlobalStates.searchOpen
        }
    }
}
