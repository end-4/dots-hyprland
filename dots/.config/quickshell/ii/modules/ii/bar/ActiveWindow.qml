import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var monitorData: HyprlandData.monitorDataFor(monitor)
    readonly property var specialWorkspace: monitorData?.specialWorkspace ?? null
    readonly property bool specialWorkspaceOpen: (specialWorkspace?.id ?? 0) < 0 && (specialWorkspace?.name ?? "") !== ""
    readonly property var effectiveActiveWorkspace: root.specialWorkspaceOpen
        ? root.specialWorkspace
        : (monitorData?.activeWorkspace ?? null)
    property var biggestWindow: {
        const ws = root.effectiveActiveWorkspace;
        if (!ws) return null;
        if (ws.name && String(ws.name).startsWith("special:"))
            return HyprlandData.biggestWindowForWorkspaceByName(ws.name);
        return HyprlandData.biggestWindowForWorkspace(ws.id);
    }

    implicitWidth: colLayout.implicitWidth

    function workspaceFallbackTitle(workspace) {
        if (!workspace) return Translation.tr("Workspace") + " 1";
        if (workspace.name && String(workspace.name).startsWith("special:")) {
            return String(workspace.name).replace(/^special:/, "");
        }
        return Translation.tr("Workspace") + " " + (workspace.id ?? 1);
    }

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated ?
                root.activeWindow?.appId :
                (root.biggestWindow?.class) ?? Translation.tr("Desktop")

        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated ?
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? root.workspaceFallbackTitle(root.effectiveActiveWorkspace)
        }

    }

}
