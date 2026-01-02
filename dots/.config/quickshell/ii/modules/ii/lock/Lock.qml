pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell.Hyprland

LockScreen {
    id: root

    lockSurface: LockSurface {
        context: root.context
    }

    // Push everything down
    property var lastWorkspaceId: 1
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
                    root.lastWorkspaceId = HyprlandData.activeWorkspace.id;
                    // Set anim to vertical and move to very very big workspace for a sliding up effect
                    Quickshell.execDetached(["hyprctl", "--batch", "keyword animation workspaces,1,7,menu_decel,slidevert; dispatch workspace 2147483647"]);
                } else {
                    Quickshell.execDetached(["hyprctl", "--batch", `dispatch workspace ${root.lastWorkspaceId}; reload`]);
                }
            }
        }
    }
}
