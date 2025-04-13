import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland

Scope {
    id: bar

    readonly property int sidebarWidth: Appearance.sizes.sidebarWidth

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarRoot
            visible: false

            property var modelData

            screen: modelData
            exclusiveZone: 0
            width: sidebarWidth
            WlrLayershell.namespace: "quickshell:sidebarRight"
            color: "transparent"

            anchors {
                top: true
                right: true
                bottom: true
            }

            // Background
            Rectangle {
                id: sidebarRightBackground

                anchors.centerIn: parent
                width: parent.width - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
            }

            // Shadow
            // DropShadow {
            //     anchors.fill: sideRightBackground
            //     horizontalOffset: 0
            //     verticalOffset: 2
            //     radius: 3
            //     samples: 17
            //     color: Appearance.m3colors.m3shadow
            //     source: sideRightBackground
            // }

            IpcHandler {
                target: "sidebarRight"

                function toggle(): void {
                    sidebarRoot.visible = !sidebarRoot.visible
                }
            }

        }

    }

}
