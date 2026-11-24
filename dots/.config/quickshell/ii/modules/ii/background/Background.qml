pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtMultimedia
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

        readonly property bool workspaceCoveredByWindow: {
            const monId = bgRoot.monitor?.id;
            const activeWsId = bgRoot.monitor?.activeWorkspace?.id;
            if (monId === undefined || activeWsId === undefined) return false;
            const screenArea = Math.max(1, bgRoot.screen.width * bgRoot.screen.height);
            let coveredArea = 0;
            for (const win of HyprlandData.windowList) {
                if (win.monitor !== monId || win.workspace?.id !== activeWsId) continue;
                if (win.hidden || win.mapped === false) continue;
                if ((win.fullscreen ?? 0) > 0) return true;
                const w = win.size?.[0] ?? 0;
                const h = win.size?.[1] ?? 0;
                coveredArea += (w * h);
            }
            return coveredArea >= screenArea * 0.80;
        }
        readonly property bool videoShouldPause: (bgRoot.liveOpt("fps") === 0)
            || (bgRoot.liveOpt("pauseOnFullscreen") && !GlobalStates.screenLocked
                && ((activeWorkspaceWithFullscreen != undefined) || workspaceCoveredByWindow || !bgRoot.visible))

        function liveOpt(key) {
            const monLive = bgRoot.monitorCfg?.live;
            if (monLive && monLive[key] !== undefined) return monLive[key];
            return Config.options.background.live[key];
        }

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property int totalWorkspaces: Math.ceil(lastWorkspaceId / workspaceChunkSize) * workspaceChunkSize
        // Wallpaper
        readonly property string monitorName: modelData?.name ?? ""
        readonly property var monitorCfg: (Config.options.background.perMonitor && monitorName !== "") ? (Config.options.background.monitors?.[monitorName] ?? null) : null
        readonly property string rawWallpaperPath: (monitorCfg?.wallpaperPath && monitorCfg.wallpaperPath !== "") ? monitorCfg.wallpaperPath : Config.options.background.wallpaperPath
        readonly property string rawThumbnailPath: (monitorCfg?.thumbnailPath && monitorCfg.thumbnailPath !== "") ? monitorCfg.thumbnailPath : Config.options.background.thumbnailPath
        readonly property bool wallpaperIsGif: rawWallpaperPath.toLowerCase().endsWith(".gif")
        property bool wallpaperIsVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaperPath)
        property string wallpaperPath: wallpaperIsVideo ? rawThumbnailPath : rawWallpaperPath
        property int videoSourceHeight: 2160
        property int videoSourceFps: 60
        property string effectiveVideoPath: ""

        function scheduleVideoPrepare() {
            if (!bgRoot.wallpaperIsVideo || bgRoot.rawWallpaperPath === "") {
                bgRoot.effectiveVideoPath = "";
                return;
            }
            videoPrepareTimer.restart();
        }

        onRawWallpaperPathChanged: scheduleVideoPrepare()
        Connections {
            target: Config.options.background
            function onMonitorsChanged() { bgRoot.scheduleVideoPrepare(); }
            function onPerMonitorChanged() { bgRoot.scheduleVideoPrepare(); }
        }
        Connections {
            target: Config.options.background.live
            function onResolutionChanged() { bgRoot.scheduleVideoPrepare(); }
            function onFpsChanged() { bgRoot.scheduleVideoPrepare(); }
        }
        Component.onCompleted: scheduleVideoPrepare()

        Timer {
            id: videoPrepareTimer
            interval: 150
            onTriggered: {
                if (!bgRoot.wallpaperIsVideo || bgRoot.rawWallpaperPath === "") return;
                const cleanPath = bgRoot.rawWallpaperPath.replace(/^file:\/\//, "");
                const reqRes = bgRoot.liveOpt("resolution") ?? "4k";
                const reqFps = bgRoot.liveOpt("fps") ?? -1;
                videoPrepareProc.command = [
                    "bash", "-c",
                    `src="$1"; req_res="$2"; req_fps="$3"
                    info=$(ffprobe -v error -select_streams v:0 -show_entries stream=height,r_frame_rate -of csv=p=0 "$src" 2>/dev/null)
                    src_h=$(echo "$info" | cut -d',' -f1 | tr -dc '0-9')
                    fps_raw=$(echo "$info" | cut -d',' -f2)
                    src_fps=$(awk -F/ '{if ($2+0>0) printf "%d", ($1/$2)+0.5; else printf "%d", $1+0}' <<< "$fps_raw")
                    [ -z "$src_h" ] && src_h=2160
                    [ -z "$src_fps" ] || [ "$src_fps" -le 0 ] && src_fps=60
                    case "$req_res" in
                        1080p) tgt_h=1080 ;;
                        2k)    tgt_h=1440 ;;
                        *)     tgt_h=2160 ;;
                    esac
                    [ "$tgt_h" -gt "$src_h" ] && tgt_h="$src_h"
                    if [ "$req_fps" -lt 0 ] || [ "$req_fps" -gt "$src_fps" ]; then
                        tgt_fps="$src_fps"
                    elif [ "$req_fps" -eq 0 ]; then
                        echo "$src_h|$src_fps|$src"
                        exit 0
                    else
                        tgt_fps="$req_fps"
                    fi
                    if [ "$tgt_h" -ge "$src_h" ] && [ "$tgt_fps" -ge "$src_fps" ]; then
                        echo "$src_h|$src_fps|$src"
                        exit 0
                    fi
                    cache_dir="$HOME/.cache/quickshell/live_wallpapers"
                    mkdir -p "$cache_dir"
                    hash=$(printf "%s" "$src" | md5sum | cut -d' ' -f1)
                    out="$cache_dir/\${hash}_\${tgt_h}p_\${tgt_fps}fps.mp4"
                    (
                        flock -x 200
                        if [ ! -s "$out" ]; then
                            tmp="$out.tmp.mp4"
                            vf=""
                            if [ "$tgt_h" -lt "$src_h" ] && [ "$tgt_fps" -lt "$src_fps" ]; then
                                vf="scale=-2:\${tgt_h},fps=\${tgt_fps}"
                            elif [ "$tgt_h" -lt "$src_h" ]; then
                                vf="scale=-2:\${tgt_h}"
                            else
                                vf="fps=\${tgt_fps}"
                            fi
                            ffmpeg -y -v error -i "$src" -vf "$vf" -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -an "$tmp" && mv -f "$tmp" "$out" || rm -f "$tmp"
                        fi
                    ) 200>"$cache_dir/.transcode.lock"
                    if [ -s "$out" ]; then
                        echo "$src_h|$src_fps|$out"
                    else
                        echo "$src_h|$src_fps|$src"
                    fi`,
                    "bash", cleanPath, reqRes, String(reqFps)
                ];
                videoPrepareProc.running = true;
            }
        }
        Process {
            id: videoPrepareProc
            stdout: StdioCollector {
                onStreamFinished: {
                    const line = text.trim();
                    if (!line) return;
                    const parts = line.split("|");
                    if (parts.length >= 3) {
                        const h = parseInt(parts[0]);
                        const f = parseInt(parts[1]);
                        const p = parts.slice(2).join("|");
                        if (!isNaN(h) && h > 0) bgRoot.videoSourceHeight = h;
                        if (!isNaN(f) && f > 0) bgRoot.videoSourceFps = f;
                        if (p && bgRoot.effectiveVideoPath !== p)
                            bgRoot.effectiveVideoPath = p;
                    }
                }
            }
        }
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        readonly property real parallaxRation: Config.options.background.parallax.workspaceZoom
        property real minSuitableScale: 1 // Some reasonable init, to be updated
        property real effectiveWallpaperScale: minSuitableScale * parallaxRation
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real scaledWallpaperWidth: wallpaperWidth * effectiveWallpaperScale
        property real scaledWallpaperHeight: wallpaperHeight * effectiveWallpaperScale
        property real parallaxTotalPixelsX: Math.max(0, scaledWallpaperWidth - screen.width)
        property real parallaxTotalPixelsY: Math.max(0, scaledWallpaperHeight - screen.height)
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
            if (!bgRoot.wallpaperPath || bgRoot.wallpaperPath === "") return;
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

                    // Perfect image; scale = 1
                    // Small picture; scale > 1; will zoom in the picture
                    // Big picture; scale < 1; will zoom out the picture
                    // Choose max number so every side will fit
                    bgRoot.minSuitableScale = Math.max(screenWidth / width, screenHeight / height);
                }
            }
        }

        Item {
            anchors.fill: parent

            // Native Live Wallpaper (Video & GIF)
            // Teardown is two-phase: the player is first stopped and detached from its
            // VideoOutput, and only after a short delay (liveGateTimer) the Loader destroys
            // it, so the render thread never samples a frame sink that is being deleted.
            Loader {
                id: liveVideoLoader
                anchors.fill: parent
                readonly property bool wanted: bgRoot.wallpaperIsVideo && !bgRoot.wallpaperSafetyTriggered && bgRoot.rawWallpaperPath !== ""
                property bool gate: false
                active: gate
                visible: active && !blurLoader.active
                Component.onCompleted: gate = wanted
                onWantedChanged: {
                    if (wanted) {
                        liveGateTimer.stop();
                        gate = true;
                        if (item) item.resume();
                    } else {
                        if (item) item.shutdown();
                        liveGateTimer.restart();
                    }
                }
                Timer {
                    id: liveGateTimer
                    interval: 300
                    onTriggered: liveVideoLoader.gate = liveVideoLoader.wanted
                }
                sourceComponent: Item {
                    id: liveRoot
                    anchors.fill: parent
                    property bool shut: false
                    function shutdown() { shut = true; bgVideoPlayer.stop(); }
                    function resume() { shut = false; if (!bgRoot.videoShouldPause) bgVideoPlayer.play(); }
                    MediaPlayer {
                        id: bgVideoPlayer
                        source: (liveRoot.shut || !bgRoot.wallpaperIsVideo || bgRoot.effectiveVideoPath === "") ? "" : "file://" + bgRoot.effectiveVideoPath
                        loops: bgRoot.liveOpt("loop") ? MediaPlayer.Infinite : 1
                        playbackRate: Math.max(0.1, bgRoot.liveOpt("speed"))
                        audioOutput: AudioOutput {
                            muted: bgRoot.liveOpt("muted")
                            volume: bgRoot.liveOpt("volume")
                        }
                        videoOutput: liveRoot.shut ? null : bgVideoOut
                        Component.onCompleted: if (!bgRoot.videoShouldPause && !liveRoot.shut && source.toString() !== "") play()
                        onSourceChanged: {
                            stop();
                            if (!bgRoot.videoShouldPause && !liveRoot.shut && source.toString() !== "") play();
                        }
                        onMediaStatusChanged: {
                            if (mediaStatus === MediaPlayer.LoadedMedia && !bgRoot.videoShouldPause && !liveRoot.shut && playbackState !== MediaPlayer.PlayingState)
                                play();
                        }
                        onErrorOccurred: (error, errorString) => console.warn("[Background] MediaPlayer error:", error, errorString)
                    }
                    Connections {
                        target: bgRoot
                        function onVideoShouldPauseChanged() {
                            if (liveRoot.shut) return;
                            if (bgRoot.videoShouldPause) bgVideoPlayer.pause();
                            else bgVideoPlayer.play();
                        }
                    }
                    VideoOutput {
                        id: bgVideoOut
                        width: parent.width
                        height: parent.height
                        x: (bgRoot.liveOpt("position") - 50) * -2
                        fillMode: bgRoot.liveOpt("fillMode") === "fit" ? VideoOutput.PreserveAspectFit
                                : bgRoot.liveOpt("fillMode") === "stretch" ? VideoOutput.Stretch
                                : VideoOutput.PreserveAspectCrop
                    }
                }
            }

            AnimatedImage {
                id: liveGifWallpaper
                anchors.fill: parent
                visible: bgRoot.wallpaperIsGif && !bgRoot.wallpaperSafetyTriggered && !blurLoader.active
                source: visible ? ("file://" + bgRoot.rawWallpaperPath.replace(/^file:\/\//, "")) : ""
                fillMode: Image.PreserveAspectCrop
                playing: visible && bgRoot.visible
                asynchronous: true
            }

            // Wallpaper
            StyledImage {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo && !bgRoot.wallpaperIsGif) ? 1 : 0
                cache: false
                smooth: false

                property int workspaceIndex: (bgRoot.monitor.activeWorkspace?.id ?? 1) - 1
                property real middleFraction: 0.5
                property real fraction: {
                    // 0 - start of the picture
                    // 1 - end of the picture
                    if (bgRoot.totalWorkspaces <= 1) {
                        return middleFraction;
                    }
                    return Math.max(0, Math.min(1, workspaceIndex / (bgRoot.totalWorkspaces - 1)));
                }

                property real usedFractionX: {
                    let usedFraction = middleFraction;
                    if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                        usedFraction = fraction;
                    }
                    if (Config.options.background.parallax.enableSidebar) {
                        let sidebarFraction = bgRoot.parallaxRation / bgRoot.workspaceChunkSize / 2;
                        usedFraction += (sidebarFraction * GlobalStates.sidebarRightOpen - sidebarFraction * GlobalStates.sidebarLeftOpen);
                    }
                    return Math.max(0, Math.min(1, usedFraction));
                }
                property real usedFractionY: {
                    let usedFraction = middleFraction;
                    if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                        usedFraction = fraction;
                    }
                    return Math.max(0, Math.min(1, usedFraction));
                }

                x: {
                    if (bgRoot.screen.width > width) {
                        // Center the picture
                        return (bgRoot.screen.width - width) / 2;
                    }
                    return - bgRoot.parallaxTotalPixelsX * usedFractionX;
                }
                y: {
                    if (bgRoot.screen.height > height) {
                        // Center the picture
                        return (bgRoot.screen.height - height) / 2;
                    }
                    return - bgRoot.parallaxTotalPixelsY * usedFractionY;
                }

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
                width: bgRoot.scaledWallpaperWidth
                height: bgRoot.scaledWallpaperHeight
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
                width: parent.width
                height: parent.height
                readonly property real parallaxFactor: {
                    var f = Config.options.background.parallax.widgetsFactor;
                    return f / bgRoot.parallaxRation;
                }
                readonly property real baseWallpaperOffsetX: (bgRoot.screen.width - wallpaper.width) / 2
                readonly property real baseWallpaperOffsetY: (bgRoot.screen.height - wallpaper.height) / 2
                readonly property real wallpaperTotalOffsetX: wallpaper.x - baseWallpaperOffsetX
                readonly property real wallpaperTotalOffsetY: wallpaper.y - baseWallpaperOffsetY
                readonly property bool locked: GlobalStates.screenLocked
                x: wallpaperTotalOffsetX * parallaxFactor * !locked
                y: wallpaperTotalOffsetY * parallaxFactor * !locked

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
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }
            }
        }
    }
}
