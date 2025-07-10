import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: screenCorners
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    Variants {
        model: Quickshell.screens

        PanelWindow {
            visible: (Config.options.appearance.fakeScreenRounding === 1 
                || (Config.options.appearance.fakeScreenRounding === 2 
                    && !activeWindow?.fullscreen))

            property var modelData

            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            mask: Region {
                item: null
            }
            // HyprlandWindow.visibleMask: Region {
            //     Region {
            //         item: topLeftCorner
            //     }
            //     Region {
            //         item: topRightCorner
            //     }
            //     Region {
            //         item: bottomLeftCorner
            //     }
            //     Region {
            //         item: bottomRightCorner
            //     }
            // }
            WlrLayershell.namespace: "quickshell:screenCorners"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            RoundCorner {
                id: topLeftCorner
                anchors.top: parent.top
                anchors.left: parent.left
                size: Appearance.rounding.screenRounding
                corner: RoundCorner.CornerEnum.TopLeft
            }
            RoundCorner {
                id: topRightCorner
                anchors.top: parent.top
                anchors.right: parent.right
                size: Appearance.rounding.screenRounding
                corner: RoundCorner.CornerEnum.TopRight
            }
            RoundCorner {
                id: bottomLeftCorner
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                size: Appearance.rounding.screenRounding
                corner: RoundCorner.CornerEnum.BottomLeft
            }
            RoundCorner {
                id: bottomRightCorner
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                size: Appearance.rounding.screenRounding
                corner: RoundCorner.CornerEnum.BottomRight
            }

        }

    }

}
