import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    required property var bar
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property int preferredWidth: Appearance.sizes.barPreferredSideSectionWidth

    height: parent.height
    width: colLayout.width
    Layout.leftMargin: Appearance.rounding.screenRounding
    

    ColumnLayout {
        id: colLayout

        anchors.centerIn: parent
        spacing: -4

        StyledText {
            font.pointSize: Appearance.font.pointSize.smaller
            color: Appearance.colors.colSubtext
            Layout.preferredWidth: preferredWidth
            elide: Text.ElideRight
            text: activeWindow?.activated ? activeWindow?.appId : "Desktop"
        }

        StyledText {
            font.pointSize: Appearance.font.pointSize.small
            color: Appearance.colors.colOnLayer0
            Layout.preferredWidth: preferredWidth
            elide: Text.ElideRight
            text: activeWindow?.activated ? activeWindow?.title : `Workspace ${monitor.activeWorkspace?.id}`
        }

    }

}
