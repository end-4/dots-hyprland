pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.ii.island

// Synced lyrics for the active track from lrclib.net, shown line by line in IslandState.lyricLine.
Item {
    id: root

    // Off by default: fetches from the network (Config.options.bar.island.lyrics).
    readonly property bool lyricsOn: IslandConfig.lyrics

    // "artist|title" -> [{ t: seconds, text }]. Misses are cached as [] so they are not refetched.
    property var cache: ({})
    property string currentKey: ""
    property string fetchingKey: ""
    property var lines: []
    property bool busy: false

    // Parses "[mm:ss.xx] text" lines. Empty-text lines are kept as timing markers.
    function parseLrc(s) {
        const out = [];
        const re = /^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/;
        for (const raw of s.split("\n")) {
            const m = re.exec(raw.trim());
            if (m)
                out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3].trim() });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    // Splits a line into word chunks of at most `max` chars, balanced so the last one isn't a lone word.
    // A single word longer than `max` stays whole (the pill elides it).
    function splitLine(text, max) {
        if (text.length <= max)
            return [text];
        const target = Math.ceil(text.length / Math.ceil(text.length / max));
        const out = [];
        let cur = "";
        for (const w of text.split(/\s+/)) {
            if (cur && (cur.length + 1 + w.length > max || cur.length >= target)) {
                out.push(cur);
                cur = w;
            } else {
                cur = cur ? cur + " " + w : w;
            }
        }
        if (cur)
            out.push(cur);
        return out;
    }

    // Lines are in seconds (Quickshell MprisPlayer.position / length).
    function updateLine() {
        const pos = MprisController.activePlayer?.position ?? 0;
        // Empty lines (instrumental breaks) keep the previous non-empty line.
        let idx = -1;
        for (let k = 0; k < root.lines.length; k++) {
            if (root.lines[k].t > pos) break;
            if (root.lines[k].text) idx = k;
        }
        let cur = "";
        if (idx >= 0) {
            // Too long for the pill: show its chunks in turn over the line's time.
            const start = root.lines[idx].t;
            const end = idx + 1 < root.lines.length ? root.lines[idx + 1].t : start + 5;
            IslandState.lyricFull = root.lines[idx].text;
            const parts = root.splitLine(root.lines[idx].text, IslandState.lyricChars);
            const i = Math.floor((pos - start) / Math.max(0.5, end - start) * parts.length);
            cur = parts[Math.max(0, Math.min(parts.length - 1, i))];
        }
        if (cur !== IslandState.lyricLine)
            IslandState.lyricLine = cur;
    }

    function kickFetch() {
        if (!root.lyricsOn || root.busy || root.currentKey === "")
            return;
        if (root.cache[root.currentKey] !== undefined)
            return;
        const t = MprisController.activeTrack;
        const len = MprisController.activePlayer?.length ?? 0;
        let args = ["curl", "-s", "--max-time", "6", "-G", "https://lrclib.net/api/get",
            "--data-urlencode", "track_name=" + (t?.title ?? ""),
            "--data-urlencode", "artist_name=" + (t?.artist ?? "")];
        if (len > 0)
            args.push("--data-urlencode", "duration=" + Math.round(len));

        root.fetchingKey = root.currentKey;
        root.busy = true;
        fetcher.command = args;
        fetcher.running = true;
    }

    // Shows the current track's lyrics from cache, or fetches them.
    function refresh() {
        if (!root.lyricsOn || root.currentKey === "")
            return;
        if (root.cache[root.currentKey] !== undefined) {
            root.lines = root.cache[root.currentKey];
            root.updateLine();
        } else {
            root.kickFetch();
        }
    }

    function onTrackChanged() {
        const t = MprisController.activeTrack;
        const key = (t?.artist ?? "") + "|" + (t?.title ?? "");
        // Art updates re-emit activeTrack with the same title; ignore those.
        if (key === root.currentKey)
            return;
        root.currentKey = key;
        root.lines = [];
        IslandState.lyricLine = "";
        if (!MprisController.activePlayer?.trackTitle)
            return;
        root.refresh();
    }

    function onFetched(text) {
        const key = root.fetchingKey;
        let parsed = null;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            parsed = null;
        }
        // Empty or broken output (network down, timeout): don't cache, a later track change retries.
        if (parsed === null)
            return;
        const lines = root.parseLrc(parsed.syncedLyrics ?? "");
        root.cache[key] = lines;
        if (key === root.currentKey) {
            root.lines = lines;
            root.updateLine();
        }
    }

    onLyricsOnChanged: {
        if (!root.lyricsOn) {
            root.lines = [];
            IslandState.lyricLine = "";
        } else {
            root.refresh();
        }
    }

    // Re-split right away when the measured capacity changes (new line, other script/font).
    Connections {
        target: IslandState
        function onLyricCharsChanged() {
            root.updateLine();
        }
    }

    Connections {
        target: MprisController
        function onActiveTrackChanged() {
            root.onTrackChanged();
        }
    }

    // Keeps the line in sync with playback. Stopped when paused or without lyrics.
    Timer {
        interval: 500
        repeat: true
        running: root.lyricsOn && root.lines.length > 0 && MprisController.isPlaying
        onTriggered: {
            // Quickshell only refreshes MprisPlayer.position when asked (same as bar/Media.qml).
            if (MprisController.activePlayer)
                MprisController.activePlayer.positionChanged();
            root.updateLine();
        }
    }

    Process {
        id: fetcher
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: root.onFetched(text)
        }
        onExited: {
            root.busy = false;
            // The track changed while this request was running: fetch the new one.
            if (root.fetchingKey !== root.currentKey)
                root.kickFetch();
        }
    }

    // Pick up whatever is already playing when the island starts.
    Component.onCompleted: root.onTrackChanged()
}
