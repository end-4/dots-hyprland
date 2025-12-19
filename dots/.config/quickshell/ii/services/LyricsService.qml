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

    property bool loading: false
    property string error: ""
    property list<var> options: []

    // 0 means "auto" (use best match).
    property int selectedId: 0

    // Show more results in the selector; UI will allow scrolling if needed.
    readonly property int maxResults: 12

    property int requestId: 0
    property string requestKey: ""
    property int attempt: 0
    property bool startPending: false
    property var _resultMap: ({})

    function normalizeTitle(rawTitle) {
        if (!rawTitle)
            return "";

        let cleaned = StringUtils.cleanMusicTitle(rawTitle);
        cleaned = cleaned.split(" - ")[0];
        cleaned = cleaned.replace(/\s*[\(\[\{][^\)\]\}]*[\)\]\}]\s*/g, " ").replace(/\s+/g, " ").trim();
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

    function buildSearchUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const title = root.queryTitle;
        const artist = root.queryArtist;
        const duration = root.queryDuration;

        if (!title || !artist)
            return "";

        if (attempt === 0) {
            let url = `${baseSearch}?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
            if (duration > 0)
                url += `&duration=${duration}`;
            return url;
        }

        if (attempt === 1)
            return `${baseSearch}?q=${encodeURIComponent(`${title} ${artist}`)}`;

        if (attempt === 2)
            return `${baseSearch}?q=${encodeURIComponent(title)}`;

        return "";
    }

    function scoreResult(item) {
        if (!item)
            return -Infinity;

        const syncedLyrics = item?.syncedLyrics ?? "";
        if (!syncedLyrics || syncedLyrics.length === 0)
            return -Infinity;

        const titleLower = root.queryTitle.toLowerCase();
        const artistLower = root.queryArtist.toLowerCase();
        const duration = root.queryDuration;

        let score = 0;
        const itemTitle = (item?.trackName ?? item?.name ?? "").toLowerCase();
        const itemArtist = (item?.artistName ?? "").toLowerCase();

        if (itemArtist && itemArtist === artistLower)
            score += 100;
        if (itemTitle && itemTitle === titleLower)
            score += 50;

        if (duration > 0 && typeof item?.duration === "number") {
            const diff = Math.abs(item.duration - duration);
            if (diff <= 2)
                score += 25;
            else if (diff <= 5)
                score += 10;
            else
                score -= Math.min(diff, 30);
        }

        if (item?.instrumental)
            score -= 1000;

        if (syncedLyrics.length < 32)
            score -= 60;

        score += Math.min(syncedLyrics.length, 4000) / 20;
        return score;
    }

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
                parsed.push({
                    time: t,
                    text
                });
            }
        }

        parsed.sort((a, b) => a.time - b.time);
        return parsed;
    }

    function syncedLyricIndexForPosition(lines, positionSeconds) {
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
            const text = lines[i].text;
            if (text && text.length > 0)
                return i;
        }

        return -1;
    }

    function currentLineForOption(option, positionSeconds) {
        if (!option)
            return "";
        if (option.instrumental)
            return "Instrumental";

        const lines = option.lines ?? [];
        if (lines.length === 0)
            return "No synced lyrics";

        const idx = syncedLyricIndexForPosition(lines, positionSeconds);
        if (idx < 0)
            return "♪";
        return lines[idx]?.text ?? "♪";
    }

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

    function resetState() {
        root.loading = false;
        root.error = "";
        root.options = [];
        root.requestKey = "";
        root.attempt = 0;
        root.startPending = false;
        root._resultMap = ({});
    }

    function ensureFetched() {
        if (!root.queryTitle || !root.queryArtist) {
            root.resetState();
            root.error = "No track info";
            return;
        }

        if (root.loading && root.requestKey === root.queryKey)
            return;

        if (fetcher.running && fetcher.requestKey === root.queryKey)
            return;

        root.requestId += 1;
        root.requestKey = root.queryKey;
        root.attempt = 0;
        root._resultMap = ({});
        root.loading = true;
        root.error = "";
        root.options = [];

        if (fetcher.running) {
            root.startPending = true;
            return;
        }

        root.fetchAttempt(root.requestId);
    }

    function fetchAttempt(requestId) {
        if (requestId !== root.requestId)
            return;
        if (root.requestKey !== root.queryKey)
            return;

        const url = root.buildSearchUrl(root.attempt);
        if (!url) {
            root.loading = false;
            root.error = "No synced lyrics";
            return;
        }

        fetcher.requestId = requestId;
        fetcher.requestKey = root.requestKey;
        fetcher.attempt = root.attempt;
        fetcher.command = ["curl", "-sL", url];
        fetcher.running = true;
    }

    Timer {
        id: fetchDebounce
        interval: 200
        repeat: false
        onTriggered: root.ensureFetched()
    }

    onQueryKeyChanged: {
        root.reloadSelection();
        root.resetState();
        if (GlobalStates.lyricsSelectorOpen)
            fetchDebounce.restart();
    }

    Process {
        id: fetcher
        property int requestId: 0
        property string requestKey: ""
        property int attempt: 0
        running: false
        command: ["curl", "-sL", "https://lrclib.net/api/search?q="]
        stdout: StdioCollector {
            onStreamFinished: {
                const requestId = fetcher.requestId;
                const requestKey = fetcher.requestKey;

                if (requestKey !== root.queryKey) {
                    if (root.startPending) {
                        root.startPending = false;
                        if (GlobalStates.lyricsSelectorOpen)
                            root.fetchAttempt(root.requestId);
                    }
                    return;
                }

                let results = [];
                try {
                    const parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) {
                        results = parsed;
                    } else if (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) {
                        results = [parsed];
                    }
                } catch (e) {
                    results = [];
                }

                for (const item of results) {
                    const id = item?.id;
                    if (!id)
                        continue;
                    const score = root.scoreResult(item);
                    if (!Number.isFinite(score))
                        continue;
                    if (score === -Infinity)
                        continue;

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
                const hasEnough = uniqueCount >= root.maxResults;

                if (!hasEnough && root.attempt < 2) {
                    root.attempt += 1;
                    root.fetchAttempt(requestId);
                    return;
                }

                const sorted = Object.values(root._resultMap)
                    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0))
                    .slice(0, root.maxResults)
                    .map(item => {
                        return Object.assign({}, item, {
                            lines: root.parseSyncedLyrics(item.syncedLyrics)
                        });
                    });

                root.options = sorted;
                root.loading = false;
                root.error = sorted.length === 0 ? "No synced lyrics" : "";
            }
        }
    }

    Connections {
        target: GlobalStates
        function onLyricsSelectorOpenChanged() {
            if (GlobalStates.lyricsSelectorOpen)
                fetchDebounce.restart();
        }
    }

    Component.onCompleted: root.reloadSelection()
}
