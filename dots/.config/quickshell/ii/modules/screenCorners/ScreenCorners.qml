import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: screenCorners
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property var actionForCorner: ({
        [RoundCorner.CornerEnum.TopLeft]: () => GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen,
        [RoundCorner.CornerEnum.BottomLeft]: () => GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen,
        [RoundCorner.CornerEnum.TopRight]: () => GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen,
        [RoundCorner.CornerEnum.BottomRight]: () => GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    })

    component CornerPanelWindow: PanelWindow {
        id: cornerPanelWindow
        property var screen: QsWindow.window?.screen
        property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
        property bool fullscreen
        visible: (Config.options.appearance.fakeScreenRounding === 1 || (Config.options.appearance.fakeScreenRounding === 2 && !fullscreen))
        property var corner

        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: sidebarCornerOpenInteractionLoader.active ? sidebarCornerOpenInteractionLoader : null
        }
        WlrLayershell.namespace: "quickshell:screenCorners"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        anchors {
            top: cornerWidget.isTopLeft || cornerWidget.isTopRight
            left: cornerWidget.isBottomLeft || cornerWidget.isTopLeft
            bottom: cornerWidget.isBottomLeft || cornerWidget.isBottomRight
            right: cornerWidget.isTopRight || cornerWidget.isBottomRight
        }
        margins {
            right: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.right) * -1
            bottom: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.bottom) * -1
        }

        implicitWidth: cornerWidget.implicitWidth
        implicitHeight: cornerWidget.implicitHeight

        RoundCorner {
            id: cornerWidget
            anchors.fill: parent
            corner: cornerPanelWindow.corner
            rightVisualMargin: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.right) * 1
            bottomVisualMargin: (Config.options.interactions.deadPixelWorkaround.enable && cornerPanelWindow.anchors.bottom) * 1

            implicitSize: Appearance.rounding.screenRounding
            implicitHeight: Math.max(implicitSize, sidebarCornerOpenInteractionLoader.implicitHeight)
            implicitWidth: Math.max(implicitSize, sidebarCornerOpenInteractionLoader.implicitWidth)

            Loader {
                id: sidebarCornerOpenInteractionLoader
                active: {
                    if (!Config.options.sidebar.cornerOpen.enable) return false;
                    if (cornerPanelWindow.fullscreen) return false;
                    return (Config.options.sidebar.cornerOpen.bottom == cornerWidget.isBottom);
                }
                anchors {
                    top: (cornerWidget.isTopLeft || cornerWidget.isTopRight) ? parent.top : undefined
                    bottom: (cornerWidget.isBottomLeft || cornerWidget.isBottomRight) ? parent.bottom : undefined
                    left: (cornerWidget.isLeft) ? parent.left : undefined
                    right: (cornerWidget.isTopRight || cornerWidget.isBottomRight) ? parent.right : undefined
                }

                sourceComponent: FocusedScrollMouseArea {
                    id: mouseArea
                    implicitWidth: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    implicitHeight: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    hoverEnabled: true
                    onMouseXChanged: {
                        if (!Config.options.sidebar.cornerOpen.clicklessCornerEnd) return;
                        if ((cornerWidget.isRight && mouseArea.mouseX >= mouseArea.width - 2)
                            || (cornerWidget.isLeft && mouseArea.mouseX <= 2))
                            screenCorners.actionForCorner[cornerPanelWindow.corner]();
                    }
                    onEntered: {
                        if (Config.options.sidebar.cornerOpen.clickless)
                            screenCorners.actionForCorner[cornerPanelWindow.corner]();
                    }
                    onPressed: {
                        screenCorners.actionForCorner[cornerPanelWindow.corner]();
                    }
                    onScrollDown: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        if (cornerWidget.isLeft)
                            cornerPanelWindow.brightnessMonitor.setBrightness(cornerPanelWindow.brightnessMonitor.brightness - 0.05);
                        else {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            Audio.sink.audio.volume -= step;
                        }
                    }
                    onScrollUp: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        if (cornerWidget.isLeft)
                            cornerPanelWindow.brightnessMonitor.setBrightness(cornerPanelWindow.brightnessMonitor.brightness + 0.05);
                        else {
                            const currentVolume = Audio.value;
                            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
                            Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
                        }
                    }
                    onMovedAway: {
                        if (!Config.options.sidebar.cornerOpen.valueScroll)
                            return;
                        if (cornerWidget.isLeft)
                            GlobalStates.osdBrightnessOpen = false;
                        else
                            GlobalStates.osdVolumeOpen = false;
                    }

                    Loader {
                        active: Config.options.sidebar.cornerOpen.visualize
                        anchors.fill: parent
                        sourceComponent: Rectangle {
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: monitorScope
            required property var modelData
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

            // Hide when fullscreen
            property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
            property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
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
