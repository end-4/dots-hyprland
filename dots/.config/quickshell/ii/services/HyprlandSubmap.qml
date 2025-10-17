pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

Singleton {
    id: root
    property string currentSubmap: "global"

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") {
                root.currentSubmap = event.data;
            }
        }
    }
}
