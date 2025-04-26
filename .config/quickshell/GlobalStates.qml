import "root:/modules/common/"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property int sidebarRightOpenCount: 0
    property bool overviewOpen: false
    property bool workspaceShowNumbers: false

    Timer {
        id: workspaceShowNumbersTimer
        interval: ConfigOptions.bar.workspaces.showNumberDelay
        // interval: 0
        repeat: false
        onTriggered: {
            workspaceShowNumbers = true
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            workspaceShowNumbersTimer.start()
        }
        onReleased: {
            workspaceShowNumbersTimer.stop()
            workspaceShowNumbers = false
        }
    }
}