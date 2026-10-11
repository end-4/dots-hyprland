pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.mediaControls

AbstractBackgroundWidget {
    id: root

    configEntryName: "music"

    readonly property list<MprisPlayer> players: MprisController.players
    readonly property MprisPlayer activePlayer: {
        if (!players || players.length === 0) return null;
        // 1. Prefer player with real art URL (avoid generic browser icon like brave/chromium)
        let withArt = players.find(p => p.trackArtUrl && p.trackArtUrl.length > 0 && !p.trackArtUrl.includes("brave") && !p.trackArtUrl.includes("chromium"));
        if (withArt) return withArt;

        // 2. Prefer player with real artist name
        let withArtist = players.find(p => p.trackArtist && p.trackArtist.length > 0);
        if (withArtist) return withArtist;

        // 3. Fallback to MprisController.activePlayer or first player
        return MprisController.activePlayer ?? players[0];
    }

    readonly property bool hasTrack: (activePlayer && ((activePlayer.trackTitle && activePlayer.trackTitle.length > 0) || (activePlayer.trackArtist && activePlayer.trackArtist.length > 0))) ?? false
    readonly property bool hideWhenIdle: Config.options.background.widgets.music?.hideWhenIdle ?? true

    visible: (!hideWhenIdle || hasTrack) && (opacity > 0)

    implicitWidth: Appearance.sizes.mediaControlsWidth
    implicitHeight: Appearance.sizes.mediaControlsHeight

    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: root.visible && (root.activePlayer?.isPlaying ?? false)
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.activePlayer !== null
        sourceComponent: PlayerControl {
            player: root.activePlayer
            visualizerPoints: root.visualizerPoints
            implicitWidth: root.implicitWidth
            implicitHeight: root.implicitHeight
            radius: Appearance.rounding.normal
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        visible: root.activePlayer === null && !root.hideWhenIdle
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.normal
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            MaterialSymbol {
                iconSize: 32
                color: Appearance.colors.colSubtext
                text: "music_off"
            }

            StyledText {
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
                text: Translation.tr("No active player")
            }
        }
    }
}
