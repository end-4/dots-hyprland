import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Scope {
    id: bar

    readonly property int sidebarWidth: Appearance.sizes.sidebarWidth

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            property var modelData

            screen: modelData
            exclusiveZone: 0
            width: sidebarWidth
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

        }

    }

}
