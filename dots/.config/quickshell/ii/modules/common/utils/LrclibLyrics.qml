pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.modules.common.functions

Item {
    id: root
    visible: false

    property bool enabled: false
    property string title: ""
    property string artist: ""
    property real duration: 0
    property real position: 0

    property bool loading: false
    property string error: ""
    property bool instrumental: false
    property var lines: []

    property string loadedKey: ""
    property string requestKey: ""
    property int requestId: 0
    property int attempt: 0
    property bool startPending: false

    readonly property string queryTitle: normalizeTitle(title)
    readonly property string queryArtist: normalizeArtist(artist)
    readonly property int queryDuration: Math.round(duration ?? 0)
    readonly property string queryKey: `${queryTitle}||${queryArtist}||${queryDuration}`

    readonly property int currentIndex: syncedLyricIndexForPosition(position)
    readonly property string currentLineText: currentIndex >= 0 ? (root.lines[currentIndex]?.text ?? "") : ""
    readonly property int prevIndex: prevNonEmptyIndex(currentIndex)
    readonly property string prevLineText: prevIndex >= 0 ? (root.lines[prevIndex]?.text ?? "") : ""
    readonly property int nextIndex: nextNonEmptyIndex(currentIndex)
    readonly property string nextLineText: nextIndex >= 0 ? (root.lines[nextIndex]?.text ?? "") : ""
    readonly property string displayText: {
        if (!root.enabled)
            return "";
        if (root.loading)
            return "Fetching lyrics…";
        if (root.instrumental)
            return "Instrumental";
        if (root.error && root.error.length > 0)
            return root.error;
        return root.currentLineText && root.currentLineText.length > 0 ? root.currentLineText : "♪";
    }

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

    function syncedLyricIndexForPosition(positionSeconds) {
        if (!root.lines || root.lines.length === 0)
            return -1;

        if (isNaN(positionSeconds) || positionSeconds < 0)
            positionSeconds = 0;

        let lo = 0;
        let hi = root.lines.length - 1;
        let idx = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (root.lines[mid].time <= positionSeconds) {
                idx = mid;
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }

        for (let i = idx; i >= 0; --i) {
            const text = root.lines[i].text;
            if (text && text.length > 0)
                return i;
        }

        return -1;
    }

    function nextNonEmptyIndex(fromIndex) {
        if (!root.lines || root.lines.length === 0)
            return -1;

        let startIndex = fromIndex;
        if (startIndex < -1)
            startIndex = -1;

        for (let i = startIndex + 1; i < root.lines.length; ++i) {
            const text = root.lines[i].text;
            if (text && text.length > 0)
                return i;
        }

        return -1;
    }

    function prevNonEmptyIndex(fromIndex) {
        if (!root.lines || root.lines.length === 0)
            return -1;

        if (fromIndex <= 0)
            return -1;

        for (let i = fromIndex - 1; i >= 0; --i) {
            const text = root.lines[i].text;
            if (text && text.length > 0)
                return i;
        }

        return -1;
    }

    function buildLyricsSearchUrl(attempt) {
        const baseSearch = "https://lrclib.net/api/search";
        const baseGet = "https://lrclib.net/api/get";
        const title = root.queryTitle;
        const artist = root.queryArtist;
        const duration = root.queryDuration;

        if (!title || !artist)
            return "";

        if (attempt === 0) {
            let url = `${baseGet}?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
            if (duration > 0)
                url += `&duration=${duration}`;
            return url;
        }

        if (attempt === 1) {
            let url = `${baseSearch}?track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}`;
            if (duration > 0)
                url += `&duration=${duration}`;
            return url;
        }

        if (attempt === 2) {
            return `${baseSearch}?q=${encodeURIComponent(`${title} ${artist}`)}`;
        }

        if (attempt === 3) {
            return `${baseSearch}?q=${encodeURIComponent(title)}`;
        }

        return "";
    }

    function pickBestLyricsResult(results) {
        if (!Array.isArray(results) || results.length === 0)
            return null;

        const titleLower = root.queryTitle.toLowerCase();
        const artistLower = root.queryArtist.toLowerCase();
        const duration = root.queryDuration;

        let best = null;
        let bestScore = -Infinity;

        for (const item of results) {
            const syncedLyrics = item?.syncedLyrics ?? "";
            if (!syncedLyrics || syncedLyrics.length === 0)
                continue;

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

            if (score > bestScore) {
                bestScore = score;
                best = item;
            }
        }

        return best;
    }

    function resetState() {
        root.loading = false;
        root.error = "";
        root.instrumental = false;
        root.lines = [];
        root.loadedKey = "";
        root.requestKey = "";
        root.attempt = 0;
        root.startPending = false;
    }

    function ensureFetched() {
        if (!root.enabled)
            return;

        if (!root.queryTitle || !root.queryArtist) {
            root.error = "No track info";
            return;
        }

        if (root.loadedKey === root.queryKey)
            return;

        if (root.loading && root.requestKey === root.queryKey)
            return;

        if (fetcher.running && fetcher.requestKey === root.queryKey)
            return;

        root.requestId += 1;
        root.attempt = 0;
        root.requestKey = root.queryKey;
        root.loading = true;
        root.error = "";
        root.instrumental = false;
        root.lines = [];

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

        const url = root.buildLyricsSearchUrl(root.attempt);
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
        interval: 250
        repeat: false
        onTriggered: root.ensureFetched()
    }

    onQueryKeyChanged: {
        root.resetState();
        if (root.enabled)
            fetchDebounce.restart();
    }

    onEnabledChanged: {
        if (root.enabled)
            fetchDebounce.restart();
        else {
            root.loading = false;
            root.startPending = false;
        }
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
                        if (root.enabled)
                            root.fetchAttempt(root.requestId);
                    }
                    return;
                }

                if (text.length === 0) {
                    root.attempt += 1;
                    root.fetchAttempt(requestId);
                    return;
                }

                try {
                    const parsed = JSON.parse(text);
                    let results = [];
                    
                    if (Array.isArray(parsed)) {
                        results = parsed;
                    } else if (parsed && typeof parsed === "object" && !parsed.code && !parsed.error) {
                        results = [parsed];
                    }

                    let filtered = results;

                    if (fetcher.attempt === 3 && root.queryArtist) {
                        const artistLower = root.queryArtist.toLowerCase();
                        filtered = results.filter(item => (item?.artistName ?? "").toLowerCase() === artistLower);
                    }

                    const best = root.pickBestLyricsResult(filtered);
                    if (!best) {
                        root.attempt += 1;
                        root.fetchAttempt(requestId);
                        return;
                    }

                    root.instrumental = best.instrumental ?? false;
                    root.lines = root.parseSyncedLyrics(best.syncedLyrics ?? "");

                    if (root.lines.length === 0 && !root.instrumental) {
                        root.attempt += 1;
                        root.fetchAttempt(requestId);
                        return;
                    }

                    root.loading = false;
                    root.error = root.lines.length === 0 && root.instrumental ? "Instrumental" : "";
                    root.loadedKey = requestKey;
                } catch (e) {
                    root.attempt += 1;
                    root.fetchAttempt(requestId);
                }
            }
        }
    }
}
