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
        model: Quickshell.screens

        PanelWindow {
            id: bgRoot

            required property var modelData

            // Hide when fullscreen
            readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
            property bool focusingThisMonitor: HyprlandData.activeWorkspace.monitor == monitor.name
            visible: !(activeWindow?.fullscreen && activeWindow?.activated && focusingThisMonitor)

            // Workspaces
            property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
            property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
            property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
            // Wallpaper
            property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4")
                || Config.options.background.wallpaperPath.endsWith(".webm")
                || Config.options.background.wallpaperPath.endsWith(".mkv")
                || Config.options.background.wallpaperPath.endsWith(".avi")
                || Config.options.background.wallpaperPath.endsWith(".mov")
            property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
            property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
            property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
            property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
            property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
            property real movableXSpace: (Math.min(wallpaperWidth * effectiveWallpaperScale, screen.width * preferredWallpaperScale) - screen.width) / 2
            property real movableYSpace: (Math.min(wallpaperHeight * effectiveWallpaperScale, screen.height * preferredWallpaperScale) - screen.height) / 2
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
            WlrLayershell.layer: GlobalStates.screenLocked ? WlrLayer.Top : WlrLayer.Bottom
            // WlrLayershell.layer: WlrLayer.Bottom
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
                command: [Quickshell.shellPath("scripts/images/least_busy_region.py"),
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
                id: wallpaper
                visible: !bgRoot.wallpaperIsVideo
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
            }

            // The clock
            Item {
                id: clock
                anchors {
                    left: wallpaper.left
                    top: wallpaper.top
                    leftMargin: ((root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX * bgRoot.effectiveWallpaperScale) - implicitWidth / 2) - (wallpaper.effectiveValue * bgRoot.movableXSpace)
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
                    anchors.centerIn: wallpaper
                    spacing: 0

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
                        Layout.topMargin: -5
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

                RowLayout {
                    anchors {
                        top: clockColumn.bottom
                        left: bgRoot.textHorizontalAlignment === Text.AlignLeft ? clockColumn.left : undefined
                        right: bgRoot.textHorizontalAlignment === Text.AlignRight ? clockColumn.right : undefined
                        horizontalCenter: bgRoot.textHorizontalAlignment === Text.AlignHCenter ? clockColumn.horizontalCenter : undefined
                        topMargin: 5
                        leftMargin: -5
                        rightMargin: -5
                    }
                    opacity: GlobalStates.screenLocked ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Item { Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignLeft; implicitWidth: 1 }
                    MaterialSymbol {
                        text: "lock"
                        Layout.fillWidth: false
                        iconSize: Appearance.font.pixelSize.huge
                        color: bgRoot.colText
                    }
                    StyledText {
                        Layout.fillWidth: false
                        text: "Locked"
                        color: bgRoot.colText
                        font {
                            pixelSize: Appearance.font.pixelSize.larger
                        }
                    }
                    Item { Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignRight; implicitWidth: 1 }

                }
            }

            // Password prompt
            StyledText {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 30
                }
                opacity: (GlobalStates.screenLocked && !GlobalStates.screenLockContainsCharacters) ? 1 : 0
                scale: opacity
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                text: "Enter password"
                color: CF.ColorUtils.transparentize(bgRoot.colText, 0.3)
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                }
            }
        }
    }
}
