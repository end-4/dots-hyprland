pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property real duration: activePlayer?.length ?? 0
    readonly property real position: activePlayer?.position ?? 0

    readonly property string queryTitle: normalizeTitle(title)
    readonly property string queryArtist: normalizeArtist(artist)
    readonly property int queryDuration: Math.round(duration ?? 0)
    readonly property string queryKey: `${queryTitle}||${queryArtist}||${queryDuration}`
    readonly property string selectionKey: Qt.md5(queryKey)
    readonly property string fetchKey: `${queryKey}||${selectedId}`

    readonly property bool lyricsEnabled: Config.options.bar.media?.showLyrics ?? false
    readonly property bool hasTrack: (title?.length > 0) && (artist?.length > 0)

    // Fetch & display state
    property bool loading: false
    property string error: ""
    property bool instrumental: false
    property var lines: []
    property string loadedKey: ""
    property list<var> options: []

    // 0 = auto (best match), >0 = user-selected lrclib ID
    property int selectedId: 0
    readonly property int maxResults: 12

    // Internal fetch state
    property int _reqId: 0
    property string _reqKey: ""
    property int _attempt: 0
    property bool _pending: false
    property var _resultMap: ({})

    // Real-time position sync
    readonly property int currentIndex: _syncedIndex(lines, position)
    readonly property string currentLineText: currentIndex >= 0 ? (lines[currentIndex]?.text ?? "") : ""
    readonly property int prevIndex: _prevNonEmpty(lines, currentIndex)
    readonly property string prevLineText: prevIndex >= 0 ? (lines[prevIndex]?.text ?? "") : ""
    readonly property int nextIndex: _nextNonEmpty(lines, currentIndex)
    readonly property string nextLineText: nextIndex >= 0 ? (lines[nextIndex]?.text ?? "") : ""
    readonly property string displayText: {
        if (!lyricsEnabled || !hasTrack) return "";
        if (loading) return "Fetching lyrics…";
        if (instrumental) return "Instrumental";
        if (error.length > 0) return error;
        return currentLineText.length > 0 ? currentLineText : "♪";
    }

    // ---- Normalization ----
    function normalizeTitle(rawTitle) {
        if (!rawTitle) return "";
        let cleaned = StringUtils.cleanMusicTitle(rawTitle);
        const parts = cleaned.split(" - ");
        let main = parts[0].trim();
        let suffix = parts.slice(1).join(" - ").trim();
        cleaned = (suffix && /\b(remix|version|edit|mix|rework)\b/i.test(suffix)) ? `${main} ${suffix}` : main;
        return cleaned.replace(/\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]\s*/g, (_, inner) => {
            if (/(?:feat\.?|ft\.?|featuring)/i.test(inner)) {
                const m = inner.replace(/^(?:feat\.?|ft\.?|featuring)\s*/i, '').trim();
                return m ? ` feat. ${m} ` : ' ';
            }
            return ' ';
        }).replace(/\s+/g, " ").trim();
    }

    function normalizeArtist(rawArtist) {
        if (!rawArtist) return "";
        return rawArtist.trim().split(",")[0].split(/ feat\.? /i)[0]
            .split(/ ft\.? /i)[0].split(/ featuring /i)[0]
            .split(/ & /)[0].split(/ x /i)[0].trim();
    }

    // ---- LRC parsing ----
    function parseSyncedLyrics(lrcText) {
        if (!lrcText) return [];
        const parsed = [];
        const timeTag = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;
        for (const rawLine of lrcText.split(/\r?\n/)) {
            if (!rawLine) continue;
            timeTag.lastIndex = 0;
            const times = [];
            let match;
            while ((match = timeTag.exec(rawLine)) !== null) {
                const frac = match[3];
                const ms = frac === undefined ? 0
                    : frac.length === 1 ? parseInt(frac, 10) * 100
                    : frac.length === 2 ? parseInt(frac, 10) * 10
                    : parseInt(frac.padEnd(3, "0"), 10);
                times.push(parseInt(match[1], 10) * 60 + parseInt(match[2], 10) + ms / 1000);
            }
            if (times.length === 0) continue;
            const text = rawLine.replace(timeTag, "").trim();
            for (const t of times) parsed.push({ time: t, text });
        }
        parsed.sort((a, b) => a.time - b.time);
        return parsed;
    }

    // ---- Position helpers ----
    function _syncedIndex(lines, pos) {
        if (!lines?.length) return -1;
        if (isNaN(pos) || pos < 0) pos = 0;
        let lo = 0, hi = lines.length - 1, idx = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].time <= pos) { idx = mid; lo = mid + 1; } else hi = mid - 1;
        }
        for (let i = idx; i >= 0; --i)
            if (lines[i].text?.length > 0) return i;
        return -1;
    }

    function _nextNonEmpty(lines, from) {
        if (!lines?.length) return -1;
        for (let i = Math.max(0, from + 1); i < lines.length; ++i)
            if (lines[i].text?.length > 0) return i;
        return -1;
    }

    function _prevNonEmpty(lines, from) {
        if (!lines?.length || from <= 0) return -1;
        for (let i = from - 1; i >= 0; --i)
            if (lines[i].text?.length > 0) return i;
        return -1;
    }

    // Preview a specific selector option at a given position
    function currentLineForOption(option, pos) {
        if (!option) return "";
        if (option.instrumental) return "Instrumental";
        const l = option.lines ?? [];
        if (l.length === 0) return "No synced lyrics";
        const idx = _syncedIndex(l, pos);
        return idx >= 0 ? (l[idx]?.text ?? "♪") : "♪";
    }

    // ---- Scoring ----
    function scoreResult(item) {
        if (!item) return -Infinity;
        const synced = item?.syncedLyrics ?? "";
        if (!synced || synced.length === 0) return -Infinity;

        let score = 0;
        const tl = root.queryTitle.toLowerCase(), al = root.queryArtist.toLowerCase();
        const rtl = (root.title || "").toLowerCase(), ral = (root.artist || "").toLowerCase();
        const it = (item?.trackName ?? item?.name ?? "").toLowerCase();
        const ia = (item?.artistName ?? "").toLowerCase();

        score += ia === ral ? 200 : ia === al ? 100 : 0;
        score += it === rtl ? 150 : it === tl ? 50 : 0;

        if (root.queryDuration > 0 && typeof item?.duration === "number") {
            const diff = Math.abs(item.duration - root.queryDuration);
            score += diff <= 2 ? 25 : diff <= 5 ? 10 : -Math.min(diff, 30);
        }
        if (item?.instrumental) score -= 1000;
        if (synced.length < 32) score -= 60;
        score += Math.min(synced.length, 4000) / 20;
        return score;
    }

    // ---- Selection persistence ----
    function reloadSelection() {
        const map = Config.options.bar.media?.lyricsSelection ?? ({});
        const parsed = Number(map[root.selectionKey]);
        root.selectedId = Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
    }

    function setSelectedIdForCurrentTrack(id) {
        root.selectedId = Math.trunc(Number(id) || 0);
        const current = Config.options.bar.media?.lyricsSelection ?? ({});
        const next = Object.assign({}, current);
        if (root.selectedId > 0) next[root.selectionKey] = root.selectedId;
        else delete next[root.selectionKey];
        Config.options.bar.media.lyricsSelection = next;
    }

    // ==== Single unified fetcher ====
    function _buildUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const baseGet = "https://lrclib.net/api/get";
        const t = root.queryTitle, a = root.queryArtist, d = root.queryDuration;
        if (!t || !a) return "";

        // If user selected a specific ID, try that first
        if (root.selectedId > 0 && attempt === 0)
            return `${baseGet}/${root.selectedId}`;
        if (root.selectedId > 0) attempt -= 1;

        if (attempt === 0) {
            // Raw title+artist exact search
            const rt = (root.title || "").trim(), ra = (root.artist || "").trim();
            if (rt && ra) {
                let url = `${baseSearch}?track_name=${encodeURIComponent(rt)}&artist_name=${encodeURIComponent(ra)}`;
                if (d > 0) url += `&duration=${d}`;
                return url;
            }
        }
        if (attempt <= 1) {
            // Normalized exact search
            let url = `${baseGet}?track_name=${encodeURIComponent(t)}&artist_name=${encodeURIComponent(a)}`;
            if (d > 0) url += `&duration=${d}`;
            return url;
        }
        if (attempt === 2)
            return `${baseSearch}?q=${encodeURIComponent(`${t} ${a}`)}`;
        if (attempt === 3)
            return `${baseSearch}?q=${encodeURIComponent(t)}`;
        return "";
    }

    function _reset() {
        root.loading = false;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        root.loadedKey = "";
        root.options = [];
        root._reqKey = "";
        root._attempt = 0;
        root._pending = false;
        root._resultMap = ({});
    }

    function _ensureFetched() {
        if (!root.lyricsEnabled || !root.hasTrack) return;
        if (root.loadedKey === root.fetchKey) return;
        if (root.loading && root._reqKey === root.fetchKey) return;
        if (fetcher.running && fetcher.reqKey === root.fetchKey) return;

        root._reqId += 1;
        root._attempt = 0;
        root._reqKey = root.fetchKey;
        root._resultMap = ({});
        root.loading = true;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        root.options = [];

        if (fetcher.running) { root._pending = true; return; }
        root._fetchAttempt(root._reqId);
    }

    function _fetchAttempt(reqId) {
        if (reqId !== root._reqId || root._reqKey !== root.fetchKey) return;
        const url = root._buildUrl(root._attempt);
        if (!url) {
            root.loading = false;
            root.error = "No synced lyrics";
            return;
        }
        fetcher.reqId = reqId;
        fetcher.reqKey = root._reqKey;
        fetcher.attempt = root._attempt;
        fetcher.command = ["curl", "-sL", url];
        fetcher.running = true;
    }

    Timer {
        id: debounce
        interval: 250; repeat: false
        onTriggered: root._ensureFetched()
    }

    onQueryKeyChanged: {
        root.reloadSelection();
        root._reset();
        if (root.lyricsEnabled && root.hasTrack)
            debounce.restart();
    }

    onSelectedIdChanged: {
        root._reset();
        if (root.lyricsEnabled && root.hasTrack)
            debounce.restart();
    }

    onLyricsEnabledChanged: {
        if (root.lyricsEnabled && root.hasTrack)
            debounce.restart();
    }

    Connections {
        target: GlobalStates
        function onLyricsSelectorOpenChanged() {
            if (GlobalStates.lyricsSelectorOpen && root.lyricsEnabled && root.hasTrack)
                debounce.restart();
        }
    }

    Process {
        id: fetcher
        property int reqId: 0
        property string reqKey: ""
        property int attempt: 0
        running: false
        command: ["curl", "-sL", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (fetcher.reqKey !== root.fetchKey) {
                    if (root._pending) {
                        root._pending = false;
                        if (root.lyricsEnabled) root._fetchAttempt(root._reqId);
                    }
                    return;
                }

                if (text.length === 0) {
                    root._attempt += 1;
                    root._fetchAttempt(fetcher.reqId);
                    return;
                }

                let results = [];
                try {
                    const parsed = JSON.parse(text);
                    results = Array.isArray(parsed) ? parsed
                        : (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) ? [parsed]
                        : [];
                } catch (e) { results = []; }

                // Filter by artist on broad title-only search
                if (fetcher.attempt === 3 && root.queryArtist) {
                    const al = root.queryArtist.toLowerCase();
                    results = results.filter(item => (item?.artistName ?? "").toLowerCase() === al);
                }

                // Accumulate deduplicated results
                for (const item of results) {
                    const id = item?.id;
                    if (!id) continue;
                    const score = root.scoreResult(item);
                    if (!Number.isFinite(score)) continue;
                    const existing = root._resultMap[id];
                    if (!existing || score > existing.score) {
                        root._resultMap[id] = {
                            id, score,
                            trackName: item?.trackName ?? item?.name ?? "",
                            artistName: item?.artistName ?? "",
                            albumName: item?.albumName ?? "",
                            duration: typeof item?.duration === "number" ? item.duration : 0,
                            instrumental: item?.instrumental ?? false,
                            syncedLyrics: item?.syncedLyrics ?? "",
                        };
                    }
                }

                const count = Object.keys(root._resultMap).length;

                // Try more attempts if we don't have enough results yet
                if (count === 0 || (count < root.maxResults && root._attempt < 3)) {
                    root._attempt += 1;
                    root._fetchAttempt(fetcher.reqId);
                    return;
                }

                // Finalize: sort by score, pick best for display, populate options for selector
                const sorted = Object.values(root._resultMap)
                    .sort((a, b) => b.score - a.score)
                    .slice(0, root.maxResults)
                    .map(item => Object.assign({}, item, { lines: root.parseSyncedLyrics(item.syncedLyrics) }));

                root.options = sorted;

                const best = sorted[0];
                if (best) {
                    root.instrumental = best.instrumental ?? false;
                    root.lines = best.lines;
                } else {
                    root.lines = [];
                }

                root.loading = false;
                root.error = sorted.length === 0 ? "No synced lyrics" : "";
                root.loadedKey = fetcher.reqKey;
            }
        }
    }

    Component.onCompleted: root.reloadSelection()
}
