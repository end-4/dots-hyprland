import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Scope {
    id: bar

    readonly property int sidebarWidth: Appearance.sizes.sidebarWidth

    Variants {
        id: sidebarVariants
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
            DropShadow {
                anchors.fill: sidebarRightBackground
                horizontalOffset: 0
                verticalOffset: 2
                radius: Appearance.sizes.elevationMargin
                samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
                color: Appearance.transparentize(Appearance.m3colors.m3shadow, 0.55)
                source: sidebarRightBackground
            }

        }

    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            for (let i = 0; i < sidebarVariants.instances.length; i++) {
                let panelWindow = sidebarVariants.instances[i];
                if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
                    panelWindow.visible = !panelWindow.visible;
                }
            }
        }
    }

}
