pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    readonly property bool fixedClockPosition: Config.options.background.fixedClockPosition
    readonly property real fixedClockX: Config.options.background.clockX
    readonly property real fixedClockY: Config.options.background.clockY

    Variants {
        // For each monitor
        model: Quickshell.screens

        PanelWindow {
            id: bgRoot

            required property var modelData
            // Workspaces
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
            property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
            property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
            // Wallpaper
            property string wallpaperPath: Config.options.background.wallpaperPath
            property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
            property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
            property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
            property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
            property real movableXSpace: (effectiveWallpaperScale - 1) / 2 * screen.width
            property real movableYSpace: (effectiveWallpaperScale - 1) / 2 * screen.height
            // Position
            property real clockX: (modelData.width / 2) + ((Math.random() < 0.5 ? -1 : 1) * modelData.width)
            property real clockY: (modelData.height / 2) + ((Math.random() < 0.5 ? -1 : 1) * modelData.height)
            property var textHorizontalAlignment: clockX < screen.width / 3 ? Text.AlignLeft :
                (clockX > screen.width * 2 / 3 ? Text.AlignRight : Text.AlignHCenter)
            // Colors
            property color dominantColor: Appearance.colors.colPrimary
            property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
            property color colText: CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))

            // Layer props
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:background"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            onWallpaperPathChanged: {
                bgRoot.updateZoomScale()
                // Clock position gets updated after zoom scale is updated
            }

            // Wallpaper zoom scale
            function updateZoomScale() {
                getWallpaperSizeProc.path = bgRoot.wallpaperPath
                getWallpaperSizeProc.running = true;
            }
            Process {
                id: getWallpaperSizeProc
                property string path: bgRoot.wallpaperPath
                command: [ "magick", "identify", "-format", "%w %h", path ]
                stdout: StdioCollector {
                    id: wallpaperSizeOutputCollector
                    onStreamFinished: {
                        const output = wallpaperSizeOutputCollector.text
                        const [width, height] = output.split(" ").map(Number);
                        bgRoot.wallpaperWidth = width
                        bgRoot.wallpaperHeight = height
                        bgRoot.effectiveWallpaperScale = Math.max(1, Math.min(
                            bgRoot.preferredWallpaperScale,
                            width / bgRoot.screen.width,
                            height / bgRoot.screen.height
                        ));

                        bgRoot.updateClockPosition()
                    }
                }
            }

            // Clock positioning
            function updateClockPosition() {
                // Somehow all this manual setting is needed to make the proc correctly use the new values
                leastBusyRegionProc.path = bgRoot.wallpaperPath
                leastBusyRegionProc.contentWidth = clock.implicitWidth
                leastBusyRegionProc.contentHeight = clock.implicitHeight
                leastBusyRegionProc.horizontalPadding = (effectiveWallpaperScale - 1) / 2 * screen.width + 100
                leastBusyRegionProc.verticalPadding = (effectiveWallpaperScale - 1) / 2 * screen.height + 100
                leastBusyRegionProc.running = false;
                leastBusyRegionProc.running = true;
            }
            Process {
                id: leastBusyRegionProc
                property string path: bgRoot.wallpaperPath
                property int contentWidth: 300
                property int contentHeight: 300
                property int horizontalPadding: bgRoot.movableXSpace
                property int verticalPadding: bgRoot.movableYSpace
                command: [Quickshell.configPath("scripts/images/least_busy_region.py"),
                    "--screen-width", bgRoot.screen.width,
                    "--screen-height", bgRoot.screen.height,
                    "--width", contentWidth,
                    "--height", contentHeight,
                    "--horizontal-padding", horizontalPadding,
                    "--vertical-padding", verticalPadding,
                    path
                ]
                stdout: StdioCollector {
                    id: leastBusyRegionOutputCollector
                    onStreamFinished: {
                        const output = leastBusyRegionOutputCollector.text
                        // console.log("[Background] Least busy region output:", output)
                        if (output.length === 0) return;
                        const parsedContent = JSON.parse(output)
                        bgRoot.clockX = parsedContent.center_x
                        bgRoot.clockY = parsedContent.center_y
                        bgRoot.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary
                    }
                }
            }

            // Wallpaper
            Image {
                property real value // 0 to 1, for offset
                value: {
                    // Range = half-groups that workspaces span on
                    const chunkSize = 5;
                    const lower = Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize;
                    const upper = Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize;
                    const range = upper - lower;
                    return (Config.options.background.parallax.enableWorkspace ? ((bgRoot.monitor.activeWorkspace.id - lower) / range) : 0.5)
                        + (0.15 * GlobalStates.sidebarRightOpen * Config.options.background.parallax.enableSidebar)
                        - (0.15 * GlobalStates.sidebarLeftOpen * Config.options.background.parallax.enableSidebar)
                }
                property real effectiveValue: Math.max(0, Math.min(1, value))
                x: -(bgRoot.movableXSpace) - (effectiveValue - 0.5) * 2 * bgRoot.movableXSpace
                y: -(bgRoot.movableYSpace)
                source: bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                sourceSize {
                    width: bgRoot.screen.width * bgRoot.effectiveWallpaperScale
                    height: bgRoot.screen.height * bgRoot.effectiveWallpaperScale
                }

                // The clock
                Item {
                    id: clock
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: ((root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX * bgRoot.effectiveWallpaperScale) - implicitWidth / 2)
                        topMargin: ((root.fixedClockPosition ? root.fixedClockY : bgRoot.clockY * bgRoot.effectiveWallpaperScale) - implicitHeight / 2)
                        Behavior on leftMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                        Behavior on topMargin {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                    }

                    implicitWidth: clockColumn.implicitWidth
                    implicitHeight: clockColumn.implicitHeight

                    ColumnLayout {
                        id: clockColumn
                        anchors.centerIn: parent
                        spacing: -5

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: bgRoot.textHorizontalAlignment
                            font {
                                family: Appearance.font.family.expressive
                                pixelSize: 90
                                weight: Font.Bold
                            }
                            color: bgRoot.colText
                            style: Text.Raised
                            styleColor: Appearance.colors.colShadow
                            text: DateTime.time
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: bgRoot.textHorizontalAlignment
                            font {
                                family: Appearance.font.family.expressive
                                pixelSize: 20
                                weight: Font.DemiBold
                            }
                            color: bgRoot.colText
                            style: Text.Raised
                            styleColor: Appearance.colors.colShadow
                            text: DateTime.date
                        }
                    }
                }
            }
        }
    }
}
