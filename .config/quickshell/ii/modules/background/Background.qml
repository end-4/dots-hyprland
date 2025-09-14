pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland


Variants {
    id: root
    readonly property bool fixedClockPosition: Config.options.background.fixedClockPosition
    readonly property real fixedClockX: Config.options.background.clockX
    readonly property real fixedClockY: Config.options.background.clockY
    readonly property real clockSizePadding: 20
    readonly property real screenSizePadding: 50
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace=>workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace=>((workspace.toplevels.values.filter(window=>window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4")
            || Config.options.background.wallpaperPath.endsWith(".webm")
            || Config.options.background.wallpaperPath.endsWith(".mkv")
            || Config.options.background.wallpaperPath.endsWith(".avi")
            || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property real wallpaperToScreenRatio: Math.min(wallpaperWidth / screen.width, wallpaperHeight / screen.height)
        property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
        property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real movableXSpace: ((wallpaperWidth / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.width) / 2
        property real movableYSpace: ((wallpaperHeight / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.height) / 2
        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Position
        property real clockX: (modelData.width / 2)
        property real clockY: (modelData.height / 2)
        property var textHorizontalAlignment: {
            if (Config.options.background.blur.enable && Config.options.background.blur.centerClock && GlobalStates.screenLocked)
                return Text.AlignHCenter;
            if (clockX < screen.width / 3)
                return Text.AlignLeft;
            if (clockX > screen.width * 2 / 3)
                return Text.AlignRight;
            return Text.AlignHCenter;
        }
        // Colors
        property color dominantColor: Appearance.colors.colPrimary
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.background.blur.enable)

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Bottom
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
                    const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
                    bgRoot.wallpaperWidth = width
                    bgRoot.wallpaperHeight = height

                    if (width <= screenWidth || height <= screenHeight) { // Undersized/perfectly sized wallpapers
                        bgRoot.effectiveWallpaperScale = Math.max(screenWidth / width, screenHeight / height);
                    } else { // Oversized = can be zoomed for parallax, yay
                        bgRoot.effectiveWallpaperScale = Math.min(
                            bgRoot.preferredWallpaperScale,
                            width / screenWidth, height / screenHeight
                        );
                    }


                    bgRoot.updateClockPosition()
                }
            }
        }

        // Clock positioning
        function updateClockPosition() {
            // Somehow all this manual setting is needed to make the proc correctly use the new values
            leastBusyRegionProc.path = bgRoot.wallpaperPath
            leastBusyRegionProc.contentWidth = clockLoader.implicitWidth + root.clockSizePadding * 2
            leastBusyRegionProc.contentHeight = clockLoader.implicitHeight + root.clockSizePadding * 2
            leastBusyRegionProc.horizontalPadding = bgRoot.movableXSpace + root.screenSizePadding * 2
            leastBusyRegionProc.verticalPadding = bgRoot.movableYSpace + root.screenSizePadding * 2
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
                "--screen-width", Math.round(bgRoot.screen.width / bgRoot.effectiveWallpaperScale),
                "--screen-height", Math.round(bgRoot.screen.height / bgRoot.effectiveWallpaperScale),
                "--width", contentWidth,
                "--height", contentHeight,
                "--horizontal-padding", horizontalPadding,
                "--vertical-padding", verticalPadding,
                path, 
                // "--visual-output",
            ]
            stdout: StdioCollector {
                id: leastBusyRegionOutputCollector
                onStreamFinished: {
                    const output = leastBusyRegionOutputCollector.text
                    // console.log("[Background] Least busy region output:", output)
                    if (output.length === 0) return;
                    const parsedContent = JSON.parse(output)
                    bgRoot.clockX = parsedContent.center_x * bgRoot.effectiveWallpaperScale
                    bgRoot.clockY = parsedContent.center_y * bgRoot.effectiveWallpaperScale
                    bgRoot.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary
                }
            }
        }

        // Wallpaper
        Image {
            id: wallpaper
            visible: opacity > 0
            opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
            cache: false
            asynchronous: true
            retainWhileLoading: true
            smooth: false
            // Range = groups that workspaces span on
            property int chunkSize: Config?.options.bar.workspaces.shown ?? 10;
            property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize;
            property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize;
            property int range: upper - lower;
            property real valueX: {
                let result = 0.5;
                if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                    result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                }
                if (Config.options.background.parallax.enableSidebar) {
                    result += (0.15 * GlobalStates.sidebarRightOpen - 0.15 * GlobalStates.sidebarLeftOpen);
                }
                return result;
            }
            property real valueY: {
                let result = 0.5;
                if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                    result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                }
                return result;
            }
            property real effectiveValueX: Math.max(0, Math.min(1, valueX))
            property real effectiveValueY: Math.max(0, Math.min(1, valueY))
            x: -(bgRoot.movableXSpace) - (effectiveValueX - 0.5) * 2 * bgRoot.movableXSpace
            y: -(bgRoot.movableYSpace) - (effectiveValueY - 0.5) * 2 * bgRoot.movableYSpace
            source: bgRoot.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            Behavior on x {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            sourceSize {
                width: bgRoot.screen.width * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
                height: bgRoot.screen.height * bgRoot.effectiveWallpaperScale * bgRoot.monitor.scale
            }
            width: bgRoot.wallpaperWidth / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
            height: bgRoot.wallpaperHeight / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
        }

        Loader {
            id: blurLoader
            active: Config.options.background.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
            anchors.fill: wallpaper
            scale: GlobalStates.screenLocked ? Config.options.background.blur.extraZoom : 1
            Behavior on scale {
                NumberAnimation {
                    id: scaleAnim
                    duration: 400
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                }
            }
            sourceComponent: GaussianBlur {
                source: wallpaper
                radius: GlobalStates.screenLocked ? Config.options.background.blur.radius : 0
                samples: radius * 2 + 1

                Rectangle {
                    anchors.fill: parent
                    color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                }
            }
        }

        // The clock
        Loader {
            id: clockLoader
            active: Config.options.background.showClock
            anchors {
                left: wallpaper.left
                top: wallpaper.top
                horizontalCenter: undefined
                leftMargin: bgRoot.movableXSpace + ((root.fixedClockPosition ? root.fixedClockX : bgRoot.clockX * bgRoot.effectiveWallpaperScale) - implicitWidth / 2)
                topMargin: {
                    if (bgRoot.shouldBlur)
                        return bgRoot.modelData.height / 3
                    return bgRoot.movableYSpace + ((root.fixedClockPosition ? root.fixedClockY : bgRoot.clockY * bgRoot.effectiveWallpaperScale) - implicitHeight / 2)
                }
                Behavior on leftMargin {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on topMargin {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }
            states: State {
                name: "centered"
                when: bgRoot.shouldBlur
                AnchorChanges {
                    target: clockLoader
                    anchors {
                        left: undefined
                        horizontalCenter: wallpaper.horizontalCenter
                        right: undefined
                    }
                }
            }
            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }
            sourceComponent: Item {
                id: clock
                implicitWidth: clockColumn.implicitWidth
                implicitHeight: clockColumn.implicitHeight

                ColumnLayout {
                    id: clockColumn
                    anchors.centerIn: parent
                    spacing: 6

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
                        animateChange: true
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
                        visible: Config.options.background.quote !== ""
                        styleColor: Appearance.colors.colShadow
                        text: Config.options.background.quote
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
                    opacity: GlobalStates.screenLocked && (!Config.options.background.blur.enable || Config.options.background.blur.showLockedText) ? 1 : 0
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
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                    }
                    StyledText {
                        Layout.fillWidth: false
                        text: "Locked"
                        color: bgRoot.colText
                        font.pixelSize: Appearance.font.pixelSize.larger
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                    }
                    Item { Layout.fillWidth: bgRoot.textHorizontalAlignment !== Text.AlignRight; implicitWidth: 1 }

                }
            }
        }
    }
}
