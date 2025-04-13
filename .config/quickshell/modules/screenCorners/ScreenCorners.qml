import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    id: screenCorners
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot
            visible: !activeWindow?.fullscreen

            property var modelData

            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            mask: Region {
                item: null
            }
            WlrLayershell.namespace: "quickshell:screenCorners"
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            RoundCorner {
                anchors.top: parent.top
                anchors.left: parent.left
                size: Appearance.rounding.screenRounding
                corner: cornerEnum.topLeft
            }
            RoundCorner {
                anchors.top: parent.top
                anchors.right: parent.right
                size: Appearance.rounding.screenRounding
                corner: cornerEnum.topRight
            }
            RoundCorner {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                size: Appearance.rounding.screenRounding
                corner: cornerEnum.bottomLeft
            }
            RoundCorner {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                size: Appearance.rounding.screenRounding
                corner: cornerEnum.bottomRight
            }

        }

    }

}
