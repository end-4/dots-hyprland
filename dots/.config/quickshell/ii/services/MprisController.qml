pragma Singleton
pragma ComponentBehavior: Bound

// From https://git.outfoxxed.me/outfoxxed/nixnew
// It does not have a license, but the author is okay with redistribution.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
	id: root;
	property list<MprisPlayer> players: Mpris.players.values.filter(player => isRealPlayer(player));
	property MprisPlayer trackedPlayer: null;
	property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null;
	signal trackChanged(reverse: bool);

	property bool __reverse: false;

	property var activeTrack;

	readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(
		p => p.dbusName?.startsWith('org.mpris.MediaPlayer2.plasma-browser-integration')
	)
	function isRealPlayer(player) {
        if (!Config.options.media.filterDuplicatePlayers) {
            return true;
        }
        return (
            // Remove native browser buses only if plasma-browser-integration is actually active on D-Bus
            !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) && !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            // playerctld just copies other buses and we don't need duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')));
    }

	// Last non-empty trackArtUrl seen per player (keyed by dbusName). Some
	// MPRIS players (Firefox via firefox-mpris, Spotify) emit transient empty
	// trackArtUrl between/during tracks. Consumers like PlayerControl that get
	// recreated on panel open/close need a stable fallback so the cover
	// doesn't vanish whenever they happen to mount during an empty window.
	// dbusName is the right key here: MprisPlayer.uniqueId in Quickshell is a
	// per-track identifier (it increments when the track changes), not a
	// per-player one, so keying on it cross-contaminates between players that
	// happen to share a uniqueId value.
	property var stableArtUrlByPlayer: ({})

	function _captureArtUrl(player) {
		if (player?.trackArtUrl?.length > 0 && !!player?.dbusName) {
			const map = Object.assign({}, root.stableArtUrlByPlayer);
			map[player.dbusName] = player.trackArtUrl;
			root.stableArtUrlByPlayer = map;
		}
	}

	// Best (largest) downloaded cover file seen per player for the current
	// track, keyed by dbusName. Persists across PlayerControl lifecycles so
	// reopening the panel doesn't downgrade to a thumbnail when Firefox
	// happens to be sitting on its low-res variant. Entry shape:
	//   { trackKey: string, artFilePath: string, artBytes: number }
	property var bestArtByPlayer: ({})

	function rememberBestArt(player, trackKey, artFilePath, artBytes) {
		const id = player?.dbusName;
		if (!id || artBytes <= 0 || !artFilePath) return;
		const existing = root.bestArtByPlayer[id];
		// Same track and existing is already >= new size: nothing to do.
		if (existing && existing.trackKey === trackKey && existing.artBytes >= artBytes) return;
		const map = Object.assign({}, root.bestArtByPlayer);
		map[id] = { trackKey: trackKey, artFilePath: artFilePath, artBytes: artBytes };
		root.bestArtByPlayer = map;
	}

	function getBestArt(player, trackKey) {
		const id = player?.dbusName;
		if (!id) return null;
		const entry = root.bestArtByPlayer[id];
		if (!entry || entry.trackKey !== trackKey) return null;
		return entry;
	}

	function _trackKeyOf(player) {
		// title|artist (album omitted on purpose). Some players (Firefox via
		// firefox-mpris) emit metadata progressively: first trackArtUrl +
		// title + artist with album="", then a moment later update album.
		// If album were part of the key, the high-res variant emitted with
		// the partial metadata and the low-res variant emitted with the
		// completed metadata would look like different tracks to the
		// "never-downgrade" guard.
		return `${player?.trackTitle ?? ""}|${player?.trackArtist ?? ""}`;
	}

	// Per-player worker. Holds a Process that downloads each new trackArtUrl
	// the player emits, regardless of whether the media controls panel is
	// open. This is what makes the cover stay sharp across panel
	// close/reopen and across auto-advance while the panel is closed —
	// PlayerControl is no longer the only thing watching for art emissions.
	component PlayerWorker: QtObject {
		id: worker
		required property MprisPlayer player

		function _fetchArt() {
			const url = worker.player?.trackArtUrl;
			if (!url || url.length === 0) return;
			artDownloader.trackKey = root._trackKeyOf(worker.player);
			artDownloader.targetFile = url;
			artDownloader.artFilePath = `${Directories.coverArt}/${Qt.md5(url)}`;
			artDownloader.running = true;
		}

		property Process artDownloader: Process {
			property string trackKey
			property string targetFile
			property string artFilePath
			property int sizeBytes: 0
			stdout: SplitParser {
				onRead: data => {
					const n = parseInt(data.trim());
					if (!isNaN(n)) artDownloader.sizeBytes = n;
				}
			}
			command: ["bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'; stat -c %s '${artFilePath}' 2>/dev/null`]
			onExited: (exitCode, exitStatus) => {
				if (exitCode !== 0 || sizeBytes <= 0 || artFilePath.length === 0) return;
				root.rememberBestArt(worker.player, trackKey, artFilePath, sizeBytes);
			}
		}

		property Connections _conn: Connections {
			target: worker.player
			function onPlaybackStateChanged() {
				if (root.trackedPlayer !== worker.player) root.trackedPlayer = worker.player;
			}
			function onTrackArtUrlChanged() {
				root._captureArtUrl(worker.player);
				worker._fetchArt();
			}
		}

		Component.onCompleted: {
			if (root.trackedPlayer == null || worker.player.isPlaying) {
				root.trackedPlayer = worker.player;
			}
			root._captureArtUrl(worker.player);
			worker._fetchArt();
		}

		Component.onDestruction: {
			if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
				for (const p of Mpris.players.values) {
					if (p.playbackState.isPlaying) {
						root.trackedPlayer = p;
						break;
					}
				}
				if (root.trackedPlayer == null && Mpris.players.values.length != 0) {
					root.trackedPlayer = Mpris.players.values[0];
				}
			}
		}
	}

	Instantiator {
		model: Mpris.players
		delegate: PlayerWorker {
			required property MprisPlayer modelData
			player: modelData
		}
	}

	Connections {
		target: activePlayer

		function onPostTrackChanged() {
			root.updateTrack();
		}

		function onTrackArtUrlChanged() {
			// console.log("arturl:", activePlayer.trackArtUrl)
			// root.updateTrack();
			if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
				// cantata likes to send cover updates *BEFORE* updating the track info.
				// as such, art url changes shouldn't be able to break the reverse animation
				const r = root.__reverse;
				root.updateTrack();
				root.__reverse = r;

			}
		}
	}

	onActivePlayerChanged: this.updateTrack();

	function updateTrack() {
		//console.log(`update: ${this.activePlayer?.trackTitle ?? ""} : ${this.activePlayer?.trackArtists}`)
		this.activeTrack = {
			uniqueId: this.activePlayer?.uniqueId ?? 0,
			artUrl: this.activePlayer?.trackArtUrl ?? "",
			title: this.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
			artist: this.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
			album: this.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
		};

		this.trackChanged(__reverse);
		this.__reverse = false;
	}

	property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying;
	property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false;
	function togglePlaying() {
		if (this.canTogglePlaying) this.activePlayer.togglePlaying();
	}

	property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false;
	function previous() {
		if (this.canGoPrevious) {
			this.__reverse = true;
			this.activePlayer.previous();
		}
	}

	property bool canGoNext: this.activePlayer?.canGoNext ?? false;
	function next() {
		if (this.canGoNext) {
			this.__reverse = false;
			this.activePlayer.next();
		}
	}

	property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl;

	property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl;
	property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None;
	function setLoopState(loopState: var) {
		if (this.loopSupported) {
			this.activePlayer.loopState = loopState;
		}
	}

	property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl;
	property bool hasShuffle: this.activePlayer?.shuffle ?? false;
	function setShuffle(shuffle: bool) {
		if (this.shuffleSupported) {
			this.activePlayer.shuffle = shuffle;
		}
	}

	function setActivePlayer(player: MprisPlayer) {
		const targetPlayer = player ?? Mpris.players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(this.activePlayer);
		} else {
			// always animate forward if going to null
			this.__reverse = false;
		}

		this.trackedPlayer = targetPlayer;
	}

	IpcHandler {
		target: "mpris"

		function pauseAll(): void {
			for (const player of Mpris.players.values) {
				if (player.canPause) player.pause();
			}
		}

		function playPause(): void { root.togglePlaying(); }
		function previous(): void { root.previous(); }
		function next(): void { root.next(); }
	}
}
