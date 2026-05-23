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

    // --- Fetch state ---
    property bool loading: false
    property string error: ""
    property bool instrumental: false
    property var lines: []
    property string loadedKey: ""

    // --- Selector state ---
    property list<var> options: []
    property bool selectorLoading: false
    property string selectorError: ""

    // 0 means "auto" (use best match).
    property int selectedId: 0
    readonly property int maxResults: 12

    // --- Internal ---
    property int requestId: 0
    property string requestKey: ""
    property int attempt: 0
    property bool startPending: false

    property int selectorRequestId: 0
    property string selectorRequestKey: ""
    property int selectorAttempt: 0
    property bool selectorStartPending: false
    property var _resultMap: ({})

    // ---- Real-time sync (replaces LrclibLyrics) ----
    readonly property int currentIndex: _syncedIndex(lines, position)
    readonly property string currentLineText: currentIndex >= 0 ? (lines[currentIndex]?.text ?? "") : ""
    readonly property int prevIndex: _prevNonEmpty(lines, currentIndex)
    readonly property string prevLineText: prevIndex >= 0 ? (lines[prevIndex]?.text ?? "") : ""
    readonly property int nextIndex: _nextNonEmpty(lines, currentIndex)
    readonly property string nextLineText: nextIndex >= 0 ? (lines[nextIndex]?.text ?? "") : ""
    readonly property string displayText: {
        if (!lyricsEnabled || !hasTrack)
            return "";
        if (loading)
            return "Fetching lyrics…";
        if (instrumental)
            return "Instrumental";
        if (error.length > 0)
            return error;
        return currentLineText.length > 0 ? currentLineText : "♪";
    }

    // ---- Text normalization ----
    function normalizeTitle(rawTitle) {
        if (!rawTitle)
            return "";

        let cleaned = StringUtils.cleanMusicTitle(rawTitle);

        const parts = cleaned.split(" - ");
        let main = parts[0].trim();
        let suffix = parts.slice(1).join(" - ").trim();
        if (suffix && /\b(remix|version|edit|mix|rework)\b/i.test(suffix))
            cleaned = `${main} ${suffix}`;
        else
            cleaned = main;

        cleaned = cleaned.replace(/\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]\s*/g, function(_, inner) {
            if (/(?:feat\.?|ft\.?|featuring)/i.test(inner)) {
                const m = inner.replace(/^(?:feat\.?|ft\.?|featuring)\s*/i, '').trim();
                return m ? ` feat. ${m} ` : ' ';
            }
            return ' ';
        }).replace(/\s+/g, " ").trim();

        return cleaned;
    }

    function normalizeArtist(rawArtist) {
        if (!rawArtist)
            return "";

        let cleaned = rawArtist.trim();
        cleaned = cleaned.split(",")[0];
        cleaned = cleaned.split(/ feat\.? /i)[0];
        cleaned = cleaned.split(/ ft\.? /i)[0];
        cleaned = cleaned.split(/ featuring /i)[0];
        cleaned = cleaned.split(/ & /)[0];
        cleaned = cleaned.split(/ x /i)[0];
        return cleaned.trim();
    }

    // ---- LRC parsing ----
    function parseSyncedLyrics(lrcText) {
        if (!lrcText)
            return [];

        const parsed = [];
        const rawLines = lrcText.split(/\r?\n/);
        const timeTag = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;

        for (const rawLine of rawLines) {
            if (!rawLine)
                continue;

            timeTag.lastIndex = 0;
            const times = [];
            let match;
            while ((match = timeTag.exec(rawLine)) !== null) {
                const minutes = parseInt(match[1], 10);
                const seconds = parseInt(match[2], 10);
                const fraction = match[3];
                let millis = 0;
                if (fraction !== undefined) {
                    if (fraction.length === 1)
                        millis = parseInt(fraction, 10) * 100;
                    else if (fraction.length === 2)
                        millis = parseInt(fraction, 10) * 10;
                    else
                        millis = parseInt(fraction.padEnd(3, "0"), 10);
                }
                times.push(minutes * 60 + seconds + millis / 1000);
            }

            if (times.length === 0)
                continue;

            const text = rawLine.replace(timeTag, "").trim();
            for (const t of times) {
                parsed.push({ time: t, text });
            }
        }

        parsed.sort((a, b) => a.time - b.time);
        return parsed;
    }

    // ---- Position sync ----
    function _syncedIndex(lines, positionSeconds) {
        if (!lines || lines.length === 0)
            return -1;

        if (isNaN(positionSeconds) || positionSeconds < 0)
            positionSeconds = 0;

        let lo = 0;
        let hi = lines.length - 1;
        let idx = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].time <= positionSeconds) {
                idx = mid;
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }

        for (let i = idx; i >= 0; --i) {
            if (lines[i].text?.length > 0)
                return i;
        }
        return -1;
    }

    function _nextNonEmpty(lines, fromIndex) {
        if (!lines || lines.length === 0)
            return -1;
        for (let i = Math.max(0, fromIndex + 1); i < lines.length; ++i) {
            if (lines[i].text?.length > 0)
                return i;
        }
        return -1;
    }

    function _prevNonEmpty(lines, fromIndex) {
        if (!lines || lines.length === 0 || fromIndex <= 0)
            return -1;
        for (let i = fromIndex - 1; i >= 0; --i) {
            if (lines[i].text?.length > 0)
                return i;
        }
        return -1;
    }

    // Used by LyricsSelector to preview a specific option's current line
    function currentLineForOption(option, positionSeconds) {
        if (!option)
            return "";
        if (option.instrumental)
            return "Instrumental";
        const l = option.lines ?? [];
        if (l.length === 0)
            return "No synced lyrics";
        const idx = _syncedIndex(l, positionSeconds);
        return idx >= 0 ? (l[idx]?.text ?? "♪") : "♪";
    }

    // ---- Scoring ----
    function scoreResult(item) {
        if (!item)
            return -Infinity;

        const syncedLyrics = item?.syncedLyrics ?? "";
        if (!syncedLyrics || syncedLyrics.length === 0)
            return -Infinity;

        const titleLower = root.queryTitle.toLowerCase();
        const artistLower = root.queryArtist.toLowerCase();
        const rawTitleLower = (root.title || "").toLowerCase();
        const rawArtistLower = (root.artist || "").toLowerCase();
        const dur = root.queryDuration;

        let score = 0;
        const itemTitle = (item?.trackName ?? item?.name ?? "").toLowerCase();
        const itemArtist = (item?.artistName ?? "").toLowerCase();

        if (itemArtist && itemArtist === rawArtistLower)
            score += 200;
        else if (itemArtist && itemArtist === artistLower)
            score += 100;

        if (itemTitle && itemTitle === rawTitleLower)
            score += 150;
        else if (itemTitle && itemTitle === titleLower)
            score += 50;

        if (dur > 0 && typeof item?.duration === "number") {
            const diff = Math.abs(item.duration - dur);
            if (diff <= 2) score += 25;
            else if (diff <= 5) score += 10;
            else score -= Math.min(diff, 30);
        }

        if (item?.instrumental)
            score -= 1000;
        if (syncedLyrics.length < 32)
            score -= 60;

        score += Math.min(syncedLyrics.length, 4000) / 20;
        return score;
    }

    // ---- Selection persistence ----
    function _readSelectedIdFromConfig() {
        const map = Config.options.bar.media?.lyricsSelection ?? ({});
        const id = map[root.selectionKey];
        const parsed = Number(id);
        return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
    }

    function reloadSelection() {
        root.selectedId = root._readSelectedIdFromConfig();
    }

    function setSelectedIdForCurrentTrack(id) {
        const nextId = Math.trunc(Number(id) || 0);
        root.selectedId = nextId;

        const current = Config.options.bar.media?.lyricsSelection ?? ({});
        const next = Object.assign({}, current);

        if (nextId > 0)
            next[root.selectionKey] = nextId;
        else
            delete next[root.selectionKey];

        Config.options.bar.media.lyricsSelection = next;
    }

    // ==== Primary fetcher (for bar display) ====
    function _buildDisplayUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const baseGet = "https://lrclib.net/api/get";
        const t = root.queryTitle;
        const a = root.queryArtist;
        const d = root.queryDuration;

        if (!t || !a) return "";

        if (root.selectedId > 0 && attempt === 0)
            return `${baseGet}/${root.selectedId}`;

        if (root.selectedId > 0) attempt -= 1;

        if (attempt === 0) {
            let url = `${baseGet}?track_name=${encodeURIComponent(t)}&artist_name=${encodeURIComponent(a)}`;
            if (d > 0) url += `&duration=${d}`;
            return url;
        }
        if (attempt === 1) {
            let url = `${baseSearch}?track_name=${encodeURIComponent(t)}&artist_name=${encodeURIComponent(a)}`;
            if (d > 0) url += `&duration=${d}`;
            return url;
        }
        if (attempt === 2)
            return `${baseSearch}?q=${encodeURIComponent(`${t} ${a}`)}`;
        if (attempt === 3)
            return `${baseSearch}?q=${encodeURIComponent(t)}`;

        return "";
    }

    function _resetDisplayState() {
        root.loading = false;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        root.loadedKey = "";
        root.requestKey = "";
        root.attempt = 0;
        root.startPending = false;
    }

    function _ensureDisplayFetched() {
        if (!root.lyricsEnabled || !root.hasTrack) return;

        if (root.loadedKey === root.fetchKey) return;
        if (root.loading && root.requestKey === root.fetchKey) return;
        if (displayFetcher.running && displayFetcher.requestKey === root.fetchKey) return;

        root.requestId += 1;
        root.attempt = 0;
        root.requestKey = root.fetchKey;
        root.loading = true;
        root.error = "";
        root.instrumental = false;
        root.lines = [];

        if (displayFetcher.running) {
            root.startPending = true;
            return;
        }
        root._fetchDisplayAttempt(root.requestId);
    }

    function _fetchDisplayAttempt(reqId) {
        if (reqId !== root.requestId || root.requestKey !== root.fetchKey) return;

        const url = root._buildDisplayUrl(root.attempt);
        if (!url) {
            root.loading = false;
            root.error = "No synced lyrics";
            return;
        }

        displayFetcher.requestId = reqId;
        displayFetcher.requestKey = root.requestKey;
        displayFetcher.attempt = root.attempt;
        displayFetcher.command = ["curl", "-sL", url];
        displayFetcher.running = true;
    }

    Timer {
        id: displayDebounce
        interval: 250
        repeat: false
        onTriggered: root._ensureDisplayFetched()
    }

    onQueryKeyChanged: {
        root.reloadSelection();
        root._resetDisplayState();
        _resetSelectorState();
        if (root.lyricsEnabled && root.hasTrack)
            displayDebounce.restart();
        if (GlobalStates.lyricsSelectorOpen)
            selectorDebounce.restart();
    }

    onSelectedIdChanged: {
        root._resetDisplayState();
        if (root.lyricsEnabled && root.hasTrack)
            displayDebounce.restart();
    }

    onLyricsEnabledChanged: {
        if (root.lyricsEnabled && root.hasTrack)
            displayDebounce.restart();
        else {
            root.loading = false;
            root.startPending = false;
        }
    }

    Process {
        id: displayFetcher
        property int requestId: 0
        property string requestKey: ""
        property int attempt: 0
        running: false
        command: ["curl", "-sL", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const reqId = displayFetcher.requestId;
                const reqKey = displayFetcher.requestKey;

                if (reqKey !== root.fetchKey) {
                    if (root.startPending) {
                        root.startPending = false;
                        if (root.lyricsEnabled)
                            root._fetchDisplayAttempt(root.requestId);
                    }
                    return;
                }

                if (text.length === 0) {
                    root.attempt += 1;
                    root._fetchDisplayAttempt(reqId);
                    return;
                }

                try {
                    const parsed = JSON.parse(text);
                    let results = Array.isArray(parsed) ? parsed
                        : (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) ? [parsed]
                        : [];

                    if (displayFetcher.attempt === 3 && root.queryArtist) {
                        const al = root.queryArtist.toLowerCase();
                        results = results.filter(item => (item?.artistName ?? "").toLowerCase() === al);
                    }

                    // Pick best result
                    let best = null;
                    let bestScore = -Infinity;
                    for (const item of results) {
                        const s = root.scoreResult(item);
                        if (s > bestScore) { bestScore = s; best = item; }
                    }

                    if (!best) {
                        root.attempt += 1;
                        root._fetchDisplayAttempt(reqId);
                        return;
                    }

                    root.instrumental = best.instrumental ?? false;
                    root.lines = root.parseSyncedLyrics(best.syncedLyrics ?? "");

                    if (root.lines.length === 0 && !root.instrumental) {
                        root.attempt += 1;
                        root._fetchDisplayAttempt(reqId);
                        return;
                    }

                    root.loading = false;
                    root.error = root.lines.length === 0 && root.instrumental ? "Instrumental" : "";
                    root.loadedKey = reqKey;
                } catch (e) {
                    root.attempt += 1;
                    root._fetchDisplayAttempt(reqId);
                }
            }
        }
    }

    // ==== Selector fetcher (for lyrics picker popup) ====
    function _buildSelectorUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const t = root.queryTitle;
        const a = root.queryArtist;
        const d = root.queryDuration;

        if (!t || !a) return "";

        if (attempt === 0) {
            const rawTitle = (root.title || "").trim();
            const rawArtist = (root.artist || "").trim();
            if (rawTitle && rawArtist) {
                let url = `${baseSearch}?track_name=${encodeURIComponent(rawTitle)}&artist_name=${encodeURIComponent(rawArtist)}`;
                if (d > 0) url += `&duration=${d}`;
                return url;
            }
        }
        if (attempt === 1)
            return `${baseSearch}?q=${encodeURIComponent(`${t} ${a}`)}`;
        if (attempt === 2)
            return `${baseSearch}?q=${encodeURIComponent(t)}`;

        return "";
    }

    function _resetSelectorState() {
        root.selectorLoading = false;
        root.selectorError = "";
        root.options = [];
        root.selectorRequestKey = "";
        root.selectorAttempt = 0;
        root.selectorStartPending = false;
        root._resultMap = ({});
    }

    function _ensureSelectorFetched() {
        if (!root.queryTitle || !root.queryArtist) {
            root._resetSelectorState();
            root.selectorError = "No track info";
            return;
        }

        if (root.selectorLoading && root.selectorRequestKey === root.queryKey) return;
        if (selectorFetcher.running && selectorFetcher.requestKey === root.queryKey) return;

        root.selectorRequestId += 1;
        root.selectorRequestKey = root.queryKey;
        root.selectorAttempt = 0;
        root._resultMap = ({});
        root.selectorLoading = true;
        root.selectorError = "";
        root.options = [];

        if (selectorFetcher.running) {
            root.selectorStartPending = true;
            return;
        }
        root._fetchSelectorAttempt(root.selectorRequestId);
    }

    function _fetchSelectorAttempt(reqId) {
        if (reqId !== root.selectorRequestId || root.selectorRequestKey !== root.queryKey) return;

        const url = root._buildSelectorUrl(root.selectorAttempt);
        if (!url) {
            root.selectorLoading = false;
            root.selectorError = "No synced lyrics";
            return;
        }

        selectorFetcher.requestId = reqId;
        selectorFetcher.requestKey = root.selectorRequestKey;
        selectorFetcher.attempt = root.selectorAttempt;
        selectorFetcher.command = ["curl", "-sL", url];
        selectorFetcher.running = true;
    }

    Timer {
        id: selectorDebounce
        interval: 200
        repeat: false
        onTriggered: root._ensureSelectorFetched()
    }

    Connections {
        target: GlobalStates
        function onLyricsSelectorOpenChanged() {
            if (GlobalStates.lyricsSelectorOpen)
                selectorDebounce.restart();
        }
    }

    Process {
        id: selectorFetcher
        property int requestId: 0
        property string requestKey: ""
        property int attempt: 0
        running: false
        command: ["curl", "-sL", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const reqId = selectorFetcher.requestId;
                const reqKey = selectorFetcher.requestKey;

                if (reqKey !== root.queryKey) {
                    if (root.selectorStartPending) {
                        root.selectorStartPending = false;
                        if (GlobalStates.lyricsSelectorOpen)
                            root._fetchSelectorAttempt(root.selectorRequestId);
                    }
                    return;
                }

                let results = [];
                try {
                    const parsed = JSON.parse(text);
                    if (Array.isArray(parsed))
                        results = parsed;
                    else if (parsed && typeof parsed === "object" && !parsed.code && !parsed.error)
                        results = [parsed];
                } catch (e) {
                    results = [];
                }

                for (const item of results) {
                    const id = item?.id;
                    if (!id) continue;
                    const score = root.scoreResult(item);
                    if (!Number.isFinite(score) || score === -Infinity) continue;

                    const existing = root._resultMap[id];
                    if (!existing || score > existing.score) {
                        root._resultMap[id] = {
                            id,
                            trackName: item?.trackName ?? item?.name ?? "",
                            artistName: item?.artistName ?? "",
                            albumName: item?.albumName ?? "",
                            duration: typeof item?.duration === "number" ? item.duration : 0,
                            instrumental: item?.instrumental ?? false,
                            syncedLyrics: item?.syncedLyrics ?? "",
                            score
                        };
                    }
                }

                const uniqueCount = Object.keys(root._resultMap).length;
                if (uniqueCount < root.maxResults && root.selectorAttempt < 2) {
                    root.selectorAttempt += 1;
                    root._fetchSelectorAttempt(reqId);
                    return;
                }

                const sorted = Object.values(root._resultMap)
                    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0))
                    .slice(0, root.maxResults)
                    .map(item => Object.assign({}, item, {
                        lines: root.parseSyncedLyrics(item.syncedLyrics)
                    }));

                root.options = sorted;
                root.selectorLoading = false;
                root.selectorError = sorted.length === 0 ? "No synced lyrics" : "";
            }
        }
    }

    Component.onCompleted: root.reloadSelection()
}
