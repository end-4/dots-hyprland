pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    // Hide ghost players: Stopped AND no title. Chromium (and others) leave
    // an MPRIS registration on D-Bus after a tab closes — still owns the
    // bus name, playbackState=Stopped, no title/artist, sometimes a stale
    // mpris:artUrl. Filtering on Stopped alone is too aggressive: real
    // players (e.g. pear-desktop / youtube-music) transition through
    // Stopped during track changes while keeping the previous trackTitle
    // set, and filtering them produces a brief "No active player"
    // placeholder flash mid-skip.
    readonly property var _rawMeaningfulPlayers: filterDuplicatePlayers(
        realPlayers.filter(p => !(p?.playbackState === MprisPlaybackState.Stopped && !p?.trackTitle))
    )

    // Stabilized view: holds the previous non-empty list for a brief grace
    // window when the raw list goes empty, so we don't destroy/recreate
    // PlayerControl delegates (and shrink/grow the panel) during normal
    // track changes. Real "all players gone" states get through after the
    // timer fires.
    property var meaningfulPlayers: _rawMeaningfulPlayers
    property bool noActivePlayers: false
    on_RawMeaningfulPlayersChanged: {
        if (_rawMeaningfulPlayers.length > 0) {
            meaningfulPlayers = _rawMeaningfulPlayers;
            noActivePlayers = false;
            noActivePlayerDelay.stop();
        } else {
            noActivePlayerDelay.restart();
        }
    }
    Timer {
        id: noActivePlayerDelay
        interval: 800
        repeat: false
        onTriggered: {
            if (root._rawMeaningfulPlayers.length === 0) {
                root.meaningfulPlayers = [];
                root.noActivePlayers = true;
            }
        }
    }
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        // Higher rank wins when picking the canonical player from a duplicate
        // group. A stale Stopped player with a non-empty artUrl should never
        // mask a live Playing one (Chromium leaves behind such ghosts).
        const playRank = p => (p?.playbackState === MprisPlaybackState.Playing) ? 2
                            : (p?.playbackState === MprisPlaybackState.Paused)  ? 1 : 0;
        const hasArt = p => !!(p?.trackArtUrl && p.trackArtUrl.length > 0);

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            // Find duplicates: matching titles, OR same playback state plus
            // near-identical position/length (plasma-browser-integration vs
            // the native browser bus). Use absolute differences — the
            // original `<= 2` on raw subtraction is true for any negative
            // diff, so a Stopped player at position=0/length=0 incorrectly
            // matches every Playing player.
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                const titleMatch = p1.trackTitle && p2.trackTitle &&
                    (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle));
                const motionMatch = p1.playbackState === p2.playbackState &&
                    Math.abs(p1.position - p2.position) <= 2 &&
                    Math.abs(p1.length - p2.length) <= 2;
                if (titleMatch || motionMatch) {
                    group.push(j);
                }
            }

            // Tiebreaker: highest play-state rank, then non-empty trackArtUrl,
            // then first encountered.
            let chosenIdx = group[0];
            for (let k = 1; k < group.length; ++k) {
                const cand = players[group[k]];
                const best = players[chosenIdx];
                if (playRank(cand) > playRank(best)) chosenIdx = group[k];
                else if (playRank(cand) === playRank(best) && hasArt(cand) && !hasArt(best)) chosenIdx = group[k];
            }

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                // Parse `;`-separated values into the visualizerPoints array
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen
        onActiveChanged: {
            if (!mediaControlsLoader.active && root.realPlayers.length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: Config.options.bar.vertical ? ((panelWindow.screen.height / 2) - widgetHeight * 1.5) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((panelWindow.screen.width / 2) - (osdWidth / 2) - widgetWidth)
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: playerColumnLayout
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.mediaControlsOpen = false;
                }
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.fill: parent
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                Repeater {
                    model: ScriptModel {
                        values: root.meaningfulPlayers
                    }
                    delegate: PlayerControl {
                        required property MprisPlayer modelData
                        player: modelData
                        visualizerPoints: root.visualizerPoints
                        implicitWidth: root.widgetWidth
                        implicitHeight: root.widgetHeight
                        radius: root.popupRounding
                    }
                }

                Item {
                    // No player placeholder
                    Layout.alignment: {
                        if (panelWindow.anchors.left)
                            return Qt.AlignLeft;
                        if (panelWindow.anchors.right)
                            return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.noActivePlayers
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle {
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 20
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if (mediaControlsLoader.active)
                Notifications.timeoutAll();
        }

        function close(): void {
            mediaControlsLoader.active = false;
        }

        function open(): void {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = true;
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = false;
        }
    }
}
