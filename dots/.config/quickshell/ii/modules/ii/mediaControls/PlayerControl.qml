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
import Quickshell.Services.Pipewire

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius
    readonly property string cavaBaseConfigPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`
    property string cavaPulseSource: ""
    property string cavaCommand: {
        const sourceLine = root.cavaPulseSource.length > 0 ? `source = ${root.cavaPulseSource}\n` : "";
        return `cava -p <(cat '${root.cavaBaseConfigPath}'; printf '\\n[input]\\nmethod = pulse\\n${sourceLine}')`;
    }

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    function normalizeToken(value) {
        return (value ?? "").toString().toLowerCase().replace(/[^a-z0-9]+/g, "");
    }

    function playerMatchTokens() {
        const tokens = new Set();
        const raw = [
            root.player?.identity,
            root.player?.desktopEntry,
            root.player?.dbusName,
            root.player?.trackArtist,
            root.player?.trackTitle
        ];
        for (const item of raw) {
            const normalized = normalizeToken(item);
            if (normalized.length > 0) {
                tokens.add(normalized);
            }
            const text = (item ?? "").toString().toLowerCase();
            if (text.length > 0) {
                for (const part of text.split(/[^a-z0-9]+/g)) {
                    const normalizedPart = normalizeToken(part);
                    if (normalizedPart.length >= 3) {
                        tokens.add(normalizedPart);
                    }
                }
            }
        }
        return [...tokens];
    }

    function streamMatchScore(node, tokens) {
        const properties = node?.properties ?? {};
        const fields = [
            properties["application.name"],
            properties["application.process.binary"],
            properties["media.name"],
            properties["node.name"],
            node?.name,
            node?.description
        ];
        let score = 0;
        for (const field of fields) {
            const normalizedField = normalizeToken(field);
            if (normalizedField.length === 0) {
                continue;
            }
            for (const token of tokens) {
                if (token.length > 0 && normalizedField.includes(token)) {
                    score += token.length;
                }
            }
        }
        return score;
    }

    function findOwnStreamNode() {
        const nodes = Audio.outputAppNodes ?? [];
        if (nodes.length === 0) {
            return null;
        }

        const tokens = playerMatchTokens();
        if (tokens.length === 0) {
            return null;
        }

        let bestNode = null;
        let bestScore = 0;
        for (const node of nodes) {
            const score = streamMatchScore(node, tokens);
            if (score > bestScore) {
                bestScore = score;
                bestNode = node;
            }
        }
        return bestScore > 0 ? bestNode : null;
    }

    function resolveSinkForStream(streamNode) {
        if (!streamNode) {
            return null;
        }

        const linkGroups = Pipewire.linkGroups?.values ?? [];
        for (const linkGroup of linkGroups) {
            const sourceNode = linkGroup?.source;
            const targetNode = linkGroup?.target;
            if (sourceNode?.id === streamNode.id && targetNode?.isSink && !targetNode?.isStream) {
                return targetNode;
            }
            if (targetNode?.id === streamNode.id && sourceNode?.isSink && !sourceNode?.isStream) {
                return sourceNode;
            }
        }

        const streamProps = streamNode?.properties ?? {};
        const hint = (streamProps["target.object"] ?? streamProps["node.target"] ?? "").toString();
        if (hint.length === 0) {
            return null;
        }

        const devices = Audio.outputDevices ?? [];
        for (const device of devices) {
            const deviceProps = device?.properties ?? {};
            const candidates = [
                device?.name,
                device?.nickname,
                device?.description,
                deviceProps["node.name"],
                deviceProps["node.nick"],
                deviceProps["object.path"]
            ];
            if (candidates.some(candidate => (candidate ?? "").toString() === hint)) {
                return device;
            }
        }
        return null;
    }

    function resolvePulseMonitorSource() {
        const streamNode = findOwnStreamNode();
        const sinkNode = resolveSinkForStream(streamNode);
        const sinkName = sinkNode?.properties?.["node.name"] ?? sinkNode?.name ?? "";
        if (!sinkName || sinkName.length === 0) {
            return "";
        }
        return sinkName.endsWith(".monitor") ? sinkName : `${sinkName}.monitor`;
    }

    function refreshVisualizerSource() {
        const newSource = resolvePulseMonitorSource();
        if (newSource === root.cavaPulseSource) {
            return;
        }
        root.cavaPulseSource = newSource;
        if (cavaProc.running) {
            cavaProc.running = false;
            cavaProc.running = true;
        }
    }

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

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    Process {
        id: cavaProc
        running: root.visible && root.player != null
        command: ["bash", "-lc", root.cavaCommand]
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Timer {
        running: cavaProc.running
        repeat: true
        interval: 1200
        onTriggered: root.refreshVisualizerSource()
    }

    onPlayerChanged: root.refreshVisualizerSource()

    Component.onCompleted: root.refreshVisualizerSource()

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

        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: background.width
            sourceSize.height: background.height
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
                    sourceSize.width: size
                    sourceSize.height: size
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