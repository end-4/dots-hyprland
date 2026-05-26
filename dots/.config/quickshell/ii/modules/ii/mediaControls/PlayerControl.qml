pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    // Some MPRIS players (Firefox via firefox-mpris, Spotify) emit empty
    // trackArtUrl between/during tracks. MprisController persists the last
    // non-empty value per player so we can fall back to it when the panel is
    // (re)opened during an empty window.
    property string artUrl: {
        const cur = player?.trackArtUrl ?? "";
        if (cur.length > 0) return cur;
        const id = player?.uniqueId;
        if (id === undefined) return "";
        return MprisController.stableArtUrlByPlayer[id] ?? "";
    }
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: artUrl.length > 0 ? `${artDownloadLocation}/${artFileName}` : ""
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius

    // Only advances when a new file is confirmed on disk. Never clears, so the
    // cover stays visible across track changes (transient empty trackArtUrl
    // from Spotify/browsers) and panel close/reopen (cached file already on
    // disk; previous design reset `downloaded` to false on every remount).
    property string displayedArtFilePath: ""

    // Track identity used to decide whether to reset best-quality tracking.
    // Firefox emits multiple artUrls per song at different resolutions (e.g.,
    // 544x544 followed by a 60x60 thumbnail); without this we'd swap to the
    // smaller thumbnail and the cover would visibly degrade.
    readonly property string _trackKey: `${player?.trackTitle ?? ""}|${player?.trackArtist ?? ""}|${player?.trackAlbum ?? ""}`
    property int _bestArtBytes: 0
    on_TrackKeyChanged: { _bestArtBytes = 0; refreshArt(); }

    component TrackChangeButton: RippleButton {
        implicitWidth: 24
        implicitHeight: 24

        property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged()
        }
    }

    function refreshArt() {
        if (root.artUrl.length === 0) return;
        // Compute the path here rather than reading root.artFilePath: on
        // onArtUrlChanged, QML may fire this handler before the chained
        // artFilePath binding re-evaluates, giving us a stale (often empty)
        // path. Deriving from artUrl directly avoids that race.
        const path = `${root.artDownloadLocation}/${Qt.md5(root.artUrl)}`;
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = path;
        coverArtDownloader.running = true;
    }

    // Trigger on artUrl change AND on (re)mount, so a cached file on disk
    // surfaces immediately when the panel is reopened. On mount we also
    // consult MprisController's per-player best-art cache so reopening the
    // panel doesn't downgrade to a thumbnail when the current trackArtUrl
    // points at a low-res variant the player emitted later (Firefox).
    Component.onCompleted: {
        const best = MprisController.getBestArt(root.player, root._trackKey);
        if (best) {
            root._bestArtBytes = best.artBytes;
            root.displayedArtFilePath = Qt.resolvedUrl(best.artFilePath);
        }
        refreshArt();
    }
    onArtUrlChanged: refreshArt()

    Process { // Cover art downloader. Emits the file size on stdout so we can
              // pick the highest-quality variant when a player advertises
              // multiple sizes for one track (Firefox does this).
        id: coverArtDownloader
        property string targetFile
        property string artFilePath
        property int sizeBytes: 0
        stdout: SplitParser {
            onRead: data => {
                const n = parseInt(data.trim());
                if (!isNaN(n)) coverArtDownloader.sizeBytes = n;
            }
        }
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'; stat -c %s '${artFilePath}' 2>/dev/null` ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || artFilePath.length === 0 || sizeBytes <= 0) return;
            // Never downgrade or rerun-flicker: only swap when the new file is
            // strictly larger than the best we've seen for this track.
            // _trackKey changes reset _bestArtBytes to 0 so a new track always
            // accepts the first hit. Strict > also rejects same-size
            // re-emissions (Chromium emits several near-identical tmp files
            // per track) which would otherwise cause StyledImage opacity flicker.
            if (sizeBytes <= root._bestArtBytes) return;
            root._bestArtBytes = sizeBytes;
            const url = Qt.resolvedUrl(artFilePath);
            if (root.displayedArtFilePath.toString() !== url.toString()) {
                root.displayedArtFilePath = url;
            }
            // Persist into MprisController so a panel close/reopen on the same
            // track can restore this best variant directly, bypassing whatever
            // (possibly lower-res) URL the player is currently advertising.
            MprisController.rememberBestArt(root.player, root._trackKey, artFilePath, sizeBytes);
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        StyledImage {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                radius: root.radius
            }
        }

        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 15

            Rectangle { // Art background
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.verysmall
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true

                    width: size
                    height: size
                }
            }

            ColumnLayout { // Info & controls
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    id: trackTitle
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                StyledText {
                    id: trackArtist
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: root.player?.trackArtist
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                    }
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        TrackChangeButton {
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                        }
                        Item {
                            id: progressBarContainer
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider { 
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    value: root.player?.position / root.player?.length
                                    onMoved: {
                                        root.player.position = value * root.player.length;
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar { 
                                    wavy: root.player?.isPlaying
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: root.player?.position / root.player?.length
                                }
                            }

                            
                        }
                        TrackChangeButton {
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                        }
                    }

                    RippleButton {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        downAction: () => root.player.togglePlaying();

                        buttonRadius: root.player?.isPlaying ? Appearance?.rounding.normal : size / 2
                        colBackground: root.player?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                        colBackgroundHover: root.player?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                        colRipple: root.player?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.huge
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: root.player?.isPlaying ? "pause" : "play_arrow"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }
                }
            }
        }
    }
}