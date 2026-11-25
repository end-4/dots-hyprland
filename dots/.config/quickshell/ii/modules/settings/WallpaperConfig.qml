import QtQuick
import QtMultimedia
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: wallpaperPage
    forceWidth: true

    property string selectedMonitor: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    property bool previewPaused: false

    readonly property string activePath: {
        if (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") {
            const entry = Config.options.background.monitors?.[wallpaperPage.selectedMonitor];
            if (entry && entry.wallpaperPath && entry.wallpaperPath !== "")
                return entry.wallpaperPath;
        }
        return Config.options.background.wallpaperPath;
    }
    readonly property bool isVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(activePath)
    readonly property bool isGif: /\.gif$/i.test(activePath)
    property int videoSourceHeight: 2160
    property int videoSourceMaxFps: 60

    onActivePathChanged: probeVideo()
    onIsVideoChanged: probeVideo()
    Component.onCompleted: probeVideo()

    function probeVideo() {
        if (!isVideo || activePath === "") return;
        const clean = activePath.replace(/^file:\/\//, "");
        probeVideoProc.command = [
            "bash", "-c",
            `info=$(ffprobe -v error -select_streams v:0 -show_entries stream=height,r_frame_rate -of csv=p=0 "$1" 2>/dev/null)
            h=$(echo "$info" | cut -d',' -f1 | tr -dc '0-9')
            fps_raw=$(echo "$info" | cut -d',' -f2)
            fps=$(awk -F/ '{if ($2+0>0) printf "%d", ($1/$2)+0.5; else printf "%d", $1+0}' <<< "$fps_raw")
            [ -n "$h" ] && [ -n "$fps" ] && echo "$h|$fps"`,
            "bash", clean
        ];
        probeVideoProc.running = true;
    }

    Process {
        id: probeVideoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length >= 2) {
                    const h = parseInt(parts[0]);
                    const f = parseInt(parts[1]);
                    if (!isNaN(h) && h > 0) wallpaperPage.videoSourceHeight = h;
                    if (!isNaN(f) && f > 0) wallpaperPage.videoSourceMaxFps = f;
                }
            }
        }
    }
    readonly property string fileName: {
        const p = activePath.replace(/^file:\/\//, "");
        const parts = p.split("/");
        return parts.length > 0 ? parts[parts.length - 1] : "";
    }

    function formatMs(ms) {
        if (!ms || ms <= 0) return "00:00";
        const totalSec = Math.floor(ms / 1000);
        const m = Math.floor(totalSec / 60);
        const s = totalSec % 60;
        return `${m < 10 ? "0" : ""}${m}:${s < 10 ? "0" : ""}${s}`;
    }

    function getLiveOpt(key) {
        if (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") {
            const monLive = Config.options.background.monitors?.[wallpaperPage.selectedMonitor]?.live;
            if (monLive && monLive[key] !== undefined) return monLive[key];
        }
        return Config.options.background.live[key];
    }

    function setLiveOpt(key, val) {
        if (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") {
            const monitors = Object.assign({}, Config.options.background.monitors || {});
            const monEntry = Object.assign({}, monitors[wallpaperPage.selectedMonitor] || {});
            const monLive = Object.assign({}, monEntry.live || {});
            monLive[key] = val;
            monEntry.live = monLive;
            monitors[wallpaperPage.selectedMonitor] = monEntry;
            Config.options.background.monitors = monitors;
        } else {
            Config.options.background.live[key] = val;
        }
    }

    LiveWallpaperStoreDialog {
        id: liveStoreDialog
        targetMonitor: Config.options.background.perMonitor ? wallpaperPage.selectedMonitor : ""
    }

    Process {
        id: randomWallProc
        property string status: ""
        command: ["bash", "-c", "true"]
        stdout: SplitParser {
            onRead: data => randomWallProc.status = data.trim()
        }
    }

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Wallpaper")
        Layout.fillWidth: true

        ConfigSwitch {
            buttonIcon: "desktop_windows"
            text: Translation.tr("Separate per monitor")
            checked: Config.options.background.perMonitor
            onCheckedChanged: {
                if (Config.options.background.perMonitor !== checked) {
                    Config.options.background.perMonitor = checked;
                }
            }
        }

        MonitorOrderPills {
            visible: Config.options.background.perMonitor
            selectedMonitor: wallpaperPage.selectedMonitor
            onMonitorSelected: name => wallpaperPage.selectedMonitor = name
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Item {
                id: wpPreviewBox
                implicitWidth: 340
                implicitHeight: 192

                NumberAnimation on opacity {
                    id: wpFadeAnim
                    from: 0.25
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                    running: false
                }
                Connections {
                    target: wallpaperPage
                    function onActivePathChanged() {
                        wallpaperPage.previewPaused = false;
                        wpFadeAnim.restart();
                    }
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: wpPreviewBox.width
                            height: wpPreviewBox.height
                            radius: Appearance.rounding.normal
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.colLayer2
                    }

                    StyledImage {
                        id: staticPreview
                        anchors.fill: parent
                        visible: !wallpaperPage.isVideo && !wallpaperPage.isGif
                        fillMode: Config.options.background.live.fillMode === "fit" ? Image.PreserveAspectFit
                                : Config.options.background.live.fillMode === "stretch" ? Image.Stretch
                                : Image.PreserveAspectCrop
                        source: visible ? wallpaperPage.activePath : ""
                        cache: true
                    }

                    AnimatedImage {
                        id: gifPreview
                        anchors.fill: parent
                        visible: wallpaperPage.isGif
                        source: visible ? ("file://" + wallpaperPage.activePath.replace(/^file:\/\//, "")) : ""
                        fillMode: Config.options.background.live.fillMode === "fit" ? Image.PreserveAspectFit
                                : Config.options.background.live.fillMode === "stretch" ? Image.Stretch
                                : Image.PreserveAspectCrop
                        playing: visible && wallpaperPage.visible && !wallpaperPage.previewPaused
                        speed: Config.options.background.live.speed
                        asynchronous: true
                    }

                    Loader {
                        id: videoPreviewLoader
                        anchors.fill: parent
                        // Two-phase teardown: stop + detach the player first, destroy the Loader item
                        // after a short delay so the render thread never samples a deleted video sink.
                        readonly property bool wanted: wallpaperPage.isVideo && wallpaperPage.visible && wallpaperPage.activePath !== ""
                        property bool gate: false
                        active: gate
                        visible: active
                        Component.onCompleted: gate = wanted
                        onWantedChanged: {
                            if (wanted) {
                                previewGateTimer.stop();
                                gate = true;
                                if (item) item.resume();
                            } else {
                                if (item) item.shutdown();
                                previewGateTimer.restart();
                            }
                        }
                        Timer {
                            id: previewGateTimer
                            interval: 300
                            onTriggered: videoPreviewLoader.gate = videoPreviewLoader.wanted
                        }
                        sourceComponent: Item {
                            id: previewRoot
                            anchors.fill: parent
                            property bool shut: false
                            function shutdown() { shut = true; wpVidPlayer.stop(); }
                            function resume() { shut = false; if (!wallpaperPage.previewPaused) wpVidPlayer.play(); }
                            MediaPlayer {
                                id: wpVidPlayer
                                source: (previewRoot.shut || !wallpaperPage.isVideo) ? "" : "file://" + wallpaperPage.activePath.replace(/^file:\/\//, "")
                                loops: Config.options.background.live.loop ? MediaPlayer.Infinite : 1
                                playbackRate: Math.max(0.1, Config.options.background.live.speed)
                                audioOutput: AudioOutput { muted: true }
                                videoOutput: previewRoot.shut ? null : wpVidOut
                                Component.onCompleted: if (!wallpaperPage.previewPaused && !previewRoot.shut && source.toString() !== "") play()
                                onSourceChanged: {
                                    stop();
                                    if (!wallpaperPage.previewPaused && !previewRoot.shut && source.toString() !== "") play();
                                }
                                onMediaStatusChanged: {
                                    if (mediaStatus === MediaPlayer.LoadedMedia && !wallpaperPage.previewPaused && !previewRoot.shut && playbackState !== MediaPlayer.PlayingState)
                                        play();
                                }
                                onErrorOccurred: (error, errorString) => console.warn("[WallpaperConfig] preview MediaPlayer error:", error, errorString)
                            }
                            Connections {
                                target: wallpaperPage
                                function onPreviewPausedChanged() {
                                    if (previewRoot.shut) return;
                                    if (wallpaperPage.previewPaused) wpVidPlayer.pause();
                                    else wpVidPlayer.play();
                                }
                            }
                            VideoOutput {
                                id: wpVidOut
                                anchors.fill: parent
                                fillMode: Config.options.background.live.fillMode === "fit" ? VideoOutput.PreserveAspectFit
                                        : Config.options.background.live.fillMode === "stretch" ? VideoOutput.Stretch
                                        : VideoOutput.PreserveAspectCrop
                            }
                        }
                    }

                    Rectangle {
                        visible: wallpaperPage.isVideo || wallpaperPage.isGif
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        radius: Appearance.rounding.full
                        color: Qt.rgba(0, 0, 0, 0.65)
                        implicitWidth: wpBadgeRow.implicitWidth + 14
                        implicitHeight: 24
                        RowLayout {
                            id: wpBadgeRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: wallpaperPage.previewPaused ? "pause_circle" : "play_circle"
                                iconSize: 14
                                color: "#ffffff"
                            }
                            StyledText {
                                text: wallpaperPage.isGif ? "GIF" : "LIVE"
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    mainText: Translation.tr("Choose file")
                    onClicked: {
                        if (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") {
                            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --monitor "${wallpaperPage.selectedMonitor}"`]);
                        } else {
                            Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                        }
                    }
                }

                RippleButtonWithIcon {
                    visible: liveStoreDialog.available !== false
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "storefront"
                    mainText: Translation.tr("Live Store")
                    onClicked: liveStoreDialog.open()
                }

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        const mon = (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") ? wallpaperPage.selectedMonitor : "";
                        randomWallProc.command = ["bash", "-c", `II_TARGET_MONITOR="${mon}" "${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/random/random_konachan_wall.sh"`];
                        randomWallProc.running = true;
                    }
                }

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        const mon = (Config.options.background.perMonitor && wallpaperPage.selectedMonitor !== "") ? wallpaperPage.selectedMonitor : "";
                        randomWallProc.command = ["bash", "-c", `II_TARGET_MONITOR="${mon}" "${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/random/random_osu_wall.sh"`];
                        randomWallProc.running = true;
                    }
                }

                RippleButtonWithIcon {
                    visible: wallpaperPage.isVideo || wallpaperPage.isGif
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: wallpaperPage.previewPaused ? "play_arrow" : "pause"
                    mainText: wallpaperPage.previewPaused ? Translation.tr("Resume preview") : Translation.tr("Pause preview")
                    onClicked: wallpaperPage.previewPaused = !wallpaperPage.previewPaused
                }
            }
        }
    }

    ContentSection {
        icon: "motion_play"
        title: Translation.tr("Live wallpaper")
        Layout.fillWidth: true

        ConfigSlider {
            buttonIcon: "speed"
            text: `${Translation.tr("Speed")}: ${Number(wallpaperPage.getLiveOpt("speed")).toFixed(2)}x`
            value: wallpaperPage.getLiveOpt("speed")
            from: 0.25
            to: 2.5
            usePercentTooltip: false
            onValueChanged: {
                const rounded = Math.round(value * 20) / 20;
                if (Math.abs(wallpaperPage.getLiveOpt("speed") - rounded) >= 0.02) {
                    wallpaperPage.setLiveOpt("speed", rounded);
                }
            }
        }

        ConfigSlider {
            buttonIcon: "swap_horiz"
            text: `${Translation.tr("Position")}: ${wallpaperPage.getLiveOpt("position")}`
            value: wallpaperPage.getLiveOpt("position")
            from: 0
            to: 100
            usePercentTooltip: false
            onValueChanged: {
                const rounded = Math.round(value);
                if (wallpaperPage.getLiveOpt("position") !== rounded) {
                    wallpaperPage.setLiveOpt("position", rounded);
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Fill mode")
            ConfigSelectionArray {
                currentValue: wallpaperPage.getLiveOpt("fillMode")
                onSelected: newValue => wallpaperPage.setLiveOpt("fillMode", newValue)
                options: [
                    { displayName: Translation.tr("Crop"), icon: "crop", value: "crop" },
                    { displayName: Translation.tr("Fit"), icon: "fit_screen", value: "fit" },
                    { displayName: Translation.tr("Stretch"), icon: "aspect_ratio", value: "stretch" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Resolution")
            ConfigSelectionArray {
                currentValue: {
                    const cfg = wallpaperPage.getLiveOpt("resolution") ?? "4k";
                    if (cfg === "4k" && wallpaperPage.videoSourceHeight < 2160) {
                        return wallpaperPage.videoSourceHeight >= 1440 ? "2k" : "1080p";
                    }
                    if (cfg === "2k" && wallpaperPage.videoSourceHeight < 1440) {
                        return "1080p";
                    }
                    return cfg;
                }
                onSelected: newValue => wallpaperPage.setLiveOpt("resolution", newValue)
                options: [
                    { displayName: "4K", icon: "4k", value: "4k", enabled: wallpaperPage.videoSourceHeight >= 2160 },
                    { displayName: "2K", icon: "2k", value: "2k", enabled: wallpaperPage.videoSourceHeight >= 1440 },
                    { displayName: "1080p", icon: "hd", value: "1080p", enabled: true }
                ]
            }
        }

        ConfigSlider {
            buttonIcon: "slow_motion_video"
            textWidth: 135
            text: {
                const fps = wallpaperPage.getLiveOpt("fps") ?? -1;
                if (fps === 0) return `${Translation.tr("Frame rate")}: 0`;
                if (fps < 0 || fps >= wallpaperPage.videoSourceMaxFps)
                    return `${Translation.tr("Frame rate")}: ${Translation.tr("Max")}`;
                return `${Translation.tr("Frame rate")}: ${fps} fps`;
            }
            value: {
                const fps = wallpaperPage.getLiveOpt("fps") ?? -1;
                return (fps < 0 || fps >= wallpaperPage.videoSourceMaxFps) ? wallpaperPage.videoSourceMaxFps : fps;
            }
            from: 0
            to: wallpaperPage.videoSourceMaxFps
            usePercentTooltip: false
            onValueChanged: {
                const rounded = Math.round(value);
                const nextFps = rounded >= wallpaperPage.videoSourceMaxFps ? -1 : rounded;
                if (wallpaperPage.getLiveOpt("fps") !== nextFps) {
                    wallpaperPage.setLiveOpt("fps", nextFps);
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "repeat"
            text: Translation.tr("Loop playback")
            checked: wallpaperPage.getLiveOpt("loop")
            onCheckedChanged: wallpaperPage.setLiveOpt("loop", checked)
        }

        ConfigSwitch {
            buttonIcon: "fullscreen"
            text: Translation.tr("Pause when fullscreen")
            checked: wallpaperPage.getLiveOpt("pauseOnFullscreen")
            onCheckedChanged: wallpaperPage.setLiveOpt("pauseOnFullscreen", checked)
        }

        ConfigSwitch {
            buttonIcon: "volume_off"
            text: Translation.tr("Mute audio")
            checked: wallpaperPage.getLiveOpt("muted")
            onCheckedChanged: wallpaperPage.setLiveOpt("muted", checked)
        }

        ConfigSlider {
            visible: !wallpaperPage.getLiveOpt("muted")
            buttonIcon: "volume_up"
            text: Translation.tr("Volume")
            value: wallpaperPage.getLiveOpt("volume")
            from: 0.0
            to: 1.0
            onValueChanged: {
                const rounded = Math.round(value * 20) / 20;
                if (Math.abs(wallpaperPage.getLiveOpt("volume") - rounded) >= 0.02) {
                    wallpaperPage.setLiveOpt("volume", rounded);
                }
            }
        }
    }
}
