pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

LockScreen {
    id: root

    lockSurface: LockSurface {
        context: root.context
    }

    // Push everything down
    property var windowData: []
    function saveWindowPositionAndTile() {
        Quickshell.execDetached(["hyprctl", "keyword", "dwindle:pseudotile", "true"]);
        root.windowData = HyprlandData.windowList.filter(w => (w.floating && w.workspace.id === HyprlandData.activeWorkspace.id));
        root.windowData.forEach(w => {
            Hyprland.dispatch(`pseudo address:${w.address}`);
            Hyprland.dispatch(`settiled address:${w.address}`);
            Hyprland.dispatch(`movetoworkspacesilent ${w.workspace.id},address:${w.address}`);
        });
    }
    function restoreWindowPositionAndTile() {
        root.windowData.forEach(w => {
            Hyprland.dispatch(`setfloating address:${w.address}`);
            Hyprland.dispatch(`movewindowpixel exact ${w.at[0]} ${w.at[1]}, address:${w.address}`);
            Hyprland.dispatch(`pseudo address:${w.address}`);
        });
        Quickshell.execDetached(["hyprctl", "keyword", "dwindle:pseudotile", "false"]);
    }
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int verticalMovementDistance: modelData.height
            property int horizontalSqueeze: modelData.width * 0.2
            onShouldPushChanged: {
                if (shouldPush) {
                    root.saveWindowPositionAndTile();
                    Quickshell.execDetached(["bash", "-c", `hyprctl keyword monitor ${targetMonitorName}, addreserved, ${verticalMovementDistance}, ${-verticalMovementDistance}, ${horizontalSqueeze}, ${horizontalSqueeze}`]);
                } else {
                    Quickshell.execDetached(["bash", "-c", `hyprctl keyword monitor ${targetMonitorName}, addreserved, 0, 0, 0, 0`]);
                    root.restoreWindowPositionAndTile();
                }
            }
        }
    }
}
