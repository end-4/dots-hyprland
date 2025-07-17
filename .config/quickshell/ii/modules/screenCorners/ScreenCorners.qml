import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: screenCorners
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    component CornerPanelWindow: PanelWindow {
        id: cornerPanelWindow
        visible: (Config.options.appearance.fakeScreenRounding === 1 || (Config.options.appearance.fakeScreenRounding === 2 && !activeWindow?.fullscreen))
        property var corner

        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: null
        }
        WlrLayershell.namespace: "quickshell:screenCorners"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        anchors {
            top: cornerPanelWindow.corner === RoundCorner.CornerEnum.TopLeft || cornerPanelWindow.corner === RoundCorner.CornerEnum.TopRight
            left: cornerPanelWindow.corner === RoundCorner.CornerEnum.TopLeft || cornerPanelWindow.corner === RoundCorner.CornerEnum.BottomLeft
            bottom: cornerPanelWindow.corner === RoundCorner.CornerEnum.BottomLeft || cornerPanelWindow.corner === RoundCorner.CornerEnum.BottomRight
            right: cornerPanelWindow.corner === RoundCorner.CornerEnum.TopRight || cornerPanelWindow.corner === RoundCorner.CornerEnum.BottomRight
        }

        implicitWidth: cornerWidget.implicitWidth
        implicitHeight: cornerWidget.implicitHeight
        RoundCorner {
            id: cornerWidget
            size: Appearance.rounding.screenRounding
            corner: cornerPanelWindow.corner
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopLeft
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopRight
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomLeft
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomRight
            }
        }
    }
}
