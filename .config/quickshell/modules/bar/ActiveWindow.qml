import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle {
    required property var bar
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    height: parent.height
    width: colLayout.width
    color: "transparent"
    Layout.leftMargin: Appearance.rounding.screenRounding
    

    ColumnLayout {
        id: colLayout

        anchors.centerIn: parent
        spacing: -4

        StyledText {
            font.pointSize: Appearance.font.pointSize.smaller
            color: Appearance.colors.colSubtext
            text: activeWindow.activated ? activeWindow?.appId : "Desktop"
        }

        StyledText {
            font.pointSize: Appearance.font.pointSize.small
            color: Appearance.colors.colOnLayer0
            text: activeWindow.activated ? activeWindow?.title : `Workspace ${monitor.activeWorkspace?.id}`
        }

    }

}
