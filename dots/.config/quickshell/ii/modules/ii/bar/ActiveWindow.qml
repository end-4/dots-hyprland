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

    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var hyprlandDataMonitor: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property bool activeIsSpecialWorkspace: Boolean(hyprlandDataMonitor?.specialWorkspace.id)
    property var currentWorkspaceID: activeIsSpecialWorkspace? hyprlandDataMonitor?.specialWorkspace.id : hyprlandDataMonitor?.activeWorkspace.id
    property var currentWorkspaceName: activeIsSpecialWorkspace? 
        capitalize(hyprlandDataMonitor?.specialWorkspace.name.replace("special:", "")) :
        hyprlandDataMonitor?.activeWorkspace.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(currentWorkspaceID)
    
    function capitalize(s) {
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    implicitWidth: colLayout.implicitWidth

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
            text: root.focusingThisMonitor && root.activeWindow?.activated && HyprlandData.activeWindow?.workspace?.id === root.currentWorkspaceID ? 
                HyprlandData.activeWindow.class :
                root.biggestWindow?.class ??
                (activeIsSpecialWorkspace ? 
                    Translation.tr("Scratchpad") :
                    root.biggestWindow?.class ?? Translation.tr("Desktop"))
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && HyprlandData.activeWindow?.workspace?.id === root.currentWorkspaceID
                ? HyprlandData.activeWindow.title
                : root.biggestWindow?.title ??
                    (activeIsSpecialWorkspace
                    ? `${Translation.tr("Workspace")} ${currentWorkspaceName}`
                    : `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`)
        }

    }

}
