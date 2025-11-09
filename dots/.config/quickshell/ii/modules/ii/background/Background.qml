pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        property real wallpaperToScreenRatio: Math.min(wallpaperWidth / screen.width, wallpaperHeight / screen.height)
        property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
        property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real movableXSpace: ((wallpaperWidth / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.width) / 2
        property real movableYSpace: ((wallpaperHeight / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.height) / 2
        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

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
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        onWallpaperPathChanged: {
            bgRoot.updateZoomScale();
            // Clock position gets updated after zoom scale is updated
        }

        // Wallpaper zoom scale
        function updateZoomScale() {
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }
        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", path]
            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = wallpaperSizeOutputCollector.text;
                    const [width, height] = output.split(" ").map(Number);
                    const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
                    bgRoot.wallpaperWidth = width;
                    bgRoot.wallpaperHeight = height;

                    if (width <= screenWidth || height <= screenHeight) {
                        // Undersized/perfectly sized wallpapers
                        bgRoot.effectiveWallpaperScale = Math.max(screenWidth / width, screenHeight / height);
                    } else {
                        // Oversized = can be zoomed for parallax, yay
                        bgRoot.effectiveWallpaperScale = Math.min(bgRoot.preferredWallpaperScale, width / screenWidth, height / screenHeight);
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            clip: true

            // Wallpaper
            StyledImage {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
                cache: false
                smooth: false
                // Range = groups that workspaces span on
                property int chunkSize: Config?.options.bar.workspaces.shown ?? 10
                property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize
                property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize
                property int range: upper - lower
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
                source: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
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
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaper
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
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
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                anchors {
                    left: wallpaper.left
                    right: wallpaper.right
                    top: wallpaper.top
                    bottom: wallpaper.bottom
                    horizontalCenter: undefined
                    verticalCenter: undefined
                    readonly property real parallaxFactor: Config.options.background.parallax.widgetsFactor
                    leftMargin: {
                        const xOnWallpaper = bgRoot.movableXSpace;
                        const extraMove = (wallpaper.effectiveValueX * 2 * bgRoot.movableXSpace) * (parallaxFactor - 1);
                        return xOnWallpaper - extraMove;
                    }
                    topMargin: {
                        const yOnWallpaper = bgRoot.movableYSpace;
                        const extraMove = (wallpaper.effectiveValueY * 2 * bgRoot.movableYSpace) * (parallaxFactor - 1);
                        return yOnWallpaper - extraMove;
                    }
                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }
                width: wallpaper.width
                height: wallpaper.height
                states: State {
                    name: "centered"
                    when: GlobalStates.screenLocked || bgRoot.wallpaperSafetyTriggered
                    PropertyChanges {
                        target: widgetCanvas
                        width: parent.width
                        height: parent.height
                    }
                    AnchorChanges {
                        target: widgetCanvas
                        anchors {
                            left: undefined
                            right: undefined
                            top: undefined
                            bottom: undefined
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }
                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.weather.enable
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }
            }
        }
    }
}
