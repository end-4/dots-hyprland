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
        property bool fullscreen
        visible: (Config.options.appearance.fakeScreenRounding === 1 || (Config.options.appearance.fakeScreenRounding === 2 && !fullscreen))
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
            implicitSize: Appearance.rounding.screenRounding
            corner: cornerPanelWindow.corner
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: monitorScope
            required property var modelData
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

            // Hide when fullscreen
            property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace=>workspace.monitor && workspace.monitor.name == monitor.name)
            property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace=>((workspace.toplevels.values.filter(window=>window.wayland.fullscreen)[0] != undefined) && workspace.active))[0]
            property bool fullscreen: activeWorkspaceWithFullscreen != undefined

            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopLeft
                fullscreen: monitorScope.fullscreen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.TopRight
                fullscreen: monitorScope.fullscreen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomLeft
                fullscreen: monitorScope.fullscreen
            }
            CornerPanelWindow {
                screen: modelData
                corner: RoundCorner.CornerEnum.BottomRight
                fullscreen: monitorScope.fullscreen
            }
        }
    }
}
