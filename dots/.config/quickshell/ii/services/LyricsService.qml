pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions
import qs.services

/**
 * Fetches time-synced lyrics for the active MPRIS track from lrclib.net.
 * A single search returns every candidate, so `options` doubles as the list
 * shown by the lyrics selector and the pool the displayed lyrics come from.
 */
Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property real position: activePlayer?.position ?? 0

    readonly property string queryTitle: normalizeTitle(title)
    readonly property string queryArtist: normalizeArtist(artist)
    readonly property int queryDuration: Math.round(activePlayer?.length ?? 0)
    readonly property string queryKey: `${queryTitle}||${queryArtist}||${queryDuration}`

    readonly property bool lyricsEnabled: Config.options.bar.media?.showLyrics ?? false
    readonly property bool hasTrack: (title.length > 0) && (artist.length > 0)
    readonly property int maxResults: 12

    property bool loading: false
    property string error: ""
    // Candidates for the current track, best match first
    property var options: []
    // 0 = automatic (best match), >0 = lrclib ID picked by the user
    property int selectedId: 0

    readonly property var selectedOption: options.find(option => option.id === root.selectedId) ?? options[0] ?? null
    readonly property var lines: selectedOption?.lines ?? []

    readonly property int currentIndex: syncedIndex(lines, position)
    readonly property string currentLineText: lines[currentIndex]?.text ?? ""
    readonly property string prevLineText: lines[nonEmptyIndex(lines, currentIndex, -1)]?.text ?? ""
    readonly property string nextLineText: lines[nonEmptyIndex(lines, currentIndex, 1)]?.text ?? ""
    readonly property string displayText: {
        if (!lyricsEnabled || !hasTrack)
            return "";
        if (loading)
            return Translation.tr("Fetching lyrics…");
        if (selectedOption?.instrumental)
            return Translation.tr("Instrumental");
        if (error.length > 0)
            return error;
        return currentLineText.length > 0 ? currentLineText : "♪";
    }

    // Strip decorations MPRIS titles pick up, but keep remix/feat. info since
    // it distinguishes otherwise identical lrclib entries.
    function normalizeTitle(rawTitle) {
        if (!rawTitle)
            return "";
        let cleaned = StringUtils.cleanMusicTitle(rawTitle);
        const parts = cleaned.split(" - ");
        const main = parts[0].trim();
        const suffix = parts.slice(1).join(" - ").trim();
        cleaned = (suffix && /\b(remix|version|edit|mix|rework)\b/i.test(suffix)) ? `${main} ${suffix}` : main;
        return cleaned.replace(/\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]\s*/g, (_, inner) => {
            if (!/(?:feat\.?|ft\.?|featuring)/i.test(inner))
                return " ";
            const featured = inner.replace(/^(?:feat\.?|ft\.?|featuring)\s*/i, "").trim();
            return featured ? ` feat. ${featured} ` : " ";
        }).replace(/\s+/g, " ").trim();
    }

    // lrclib indexes one primary artist, so drop collaborators
    function normalizeArtist(rawArtist) {
        if (!rawArtist)
            return "";
        return rawArtist.split(/,| feat\.? | ft\.? | featuring | & | x /i)[0].trim();
    }

    function parseSyncedLyrics(lrcText) {
        if (!lrcText)
            return [];
        const parsed = [];
        const timeTag = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;
        for (const rawLine of lrcText.split(/\r?\n/)) {
            const text = rawLine.replace(timeTag, "").trim();
            timeTag.lastIndex = 0;
            let match;
            while ((match = timeTag.exec(rawLine)) !== null) {
                // A tag may carry 1-3 fraction digits: .5 = 500ms, .05 = 50ms, .005 = 5ms
                const ms = match[3] === undefined ? 0 : parseInt(match[3].padEnd(3, "0"), 10);
                parsed.push({
                    time: parseInt(match[1], 10) * 60 + parseInt(match[2], 10) + ms / 1000,
                    text: text
                });
            }
        }
        return parsed.sort((a, b) => a.time - b.time);
    }

    // Last line whose timestamp has passed, skipping the blank spacer lines
    function syncedIndex(lines, pos) {
        if (!lines?.length)
            return -1;
        const at = (isNaN(pos) || pos < 0) ? 0 : pos;
        let lo = 0, hi = lines.length - 1, idx = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].time <= at) {
                idx = mid;
                lo = mid + 1;
            } else
                hi = mid - 1;
        }
        return nonEmptyIndex(lines, idx + 1, -1);
    }

    // Nearest index with actual text, searching in `step` direction from `from`
    function nonEmptyIndex(lines, from, step) {
        for (let i = from + step; i >= 0 && i < (lines?.length ?? 0); i += step) {
            if (lines[i].text.length > 0)
                return i;
        }
        return -1;
    }

    function lineTextForOption(option, pos) {
        if (option?.instrumental)
            return Translation.tr("Instrumental");
        if (!option?.lines?.length)
            return Translation.tr("No synced lyrics");
        return option.lines[syncedIndex(option.lines, pos)]?.text ?? "♪";
    }

    // Rank candidates so the automatic pick usually matches what's playing
    function scoreResult(item) {
        const synced = item?.syncedLyrics ?? "";
        if (synced.length === 0)
            return -Infinity;

        const itemTitle = (item.trackName ?? "").toLowerCase();
        const itemArtist = (item.artistName ?? "").toLowerCase();
        let score = 0;

        score += itemArtist === root.artist.toLowerCase() ? 200 : itemArtist === root.queryArtist.toLowerCase() ? 100 : 0;
        score += itemTitle === root.title.toLowerCase() ? 150 : itemTitle === root.queryTitle.toLowerCase() ? 50 : 0;

        if (root.queryDuration > 0 && typeof item.duration === "number") {
            const diff = Math.abs(item.duration - root.queryDuration);
            score += diff <= 2 ? 25 : diff <= 5 ? 10 : -Math.min(diff, 30);
        }
        if (item.instrumental)
            score -= 1000;
        if (synced.length < 32)
            score -= 60;
        return score + Math.min(synced.length, 4000) / 20;
    }

    function loadSelection() {
        const stored = Array.from(Config.options.bar.media?.lyricsSelection ?? []).find(entry => entry.track === root.queryKey);
        root.selectedId = Math.trunc(Number(stored?.id) || 0);
    }

    function setSelectedIdForCurrentTrack(id) {
        root.selectedId = Math.trunc(Number(id) || 0);
        const selection = Array.from(Config.options.bar.media.lyricsSelection).filter(entry => entry.track !== root.queryKey);
        if (root.selectedId > 0)
            selection.push({ track: root.queryKey, id: root.selectedId });
        // Bound the list so it can't grow forever in the config file
        Config.options.bar.media.lyricsSelection = selection.slice(-50);
    }

    function fetch(useFreeTextSearch) {
        if (!root.lyricsEnabled || !root.hasTrack || !root.queryTitle || !root.queryArtist)
            return;
        const query = useFreeTextSearch ? `q=${encodeURIComponent(`${root.queryTitle} ${root.queryArtist}`)}` : `track_name=${encodeURIComponent(root.queryTitle)}&artist_name=${encodeURIComponent(root.queryArtist)}`;
        root.loading = true;
        root.error = "";
        fetcher.usedFreeTextSearch = useFreeTextSearch;
        fetcher.trackKey = root.queryKey;
        fetcher.url = `https://lrclib.net/api/search?${query}`;
        fetcher.running = true;
    }

    onQueryKeyChanged: {
        root.options = [];
        root.error = "";
        root.loading = false;
        root.loadSelection();
        debounce.restart();
    }
    onLyricsEnabledChanged: if (root.lyricsEnabled) debounce.restart()

    Timer {
        id: debounce
        // Metadata fields arrive one at a time on track change; wait for them to settle
        interval: 250
        onTriggered: root.fetch(false)
    }

    Process {
        id: fetcher
        property bool usedFreeTextSearch: false
        property string trackKey: ""
        property string url: ""
        // Bail out instead of leaving `loading` stuck when the network stalls
        command: ["curl", "-sfL", "--connect-timeout", "5", "--max-time", "10", url]

        onExited: (exitCode, exitStatus) => {
            // `running` means the empty response already triggered the retry below
            if (exitCode === 0 || fetcher.running || fetcher.trackKey !== root.queryKey)
                return;
            root.loading = false;
            root.error = Translation.tr("Couldn't reach lrclib");
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (fetcher.trackKey !== root.queryKey)
                    return; // Track changed mid-flight; a newer fetch owns the state

                let results = [];
                try {
                    const parsed = JSON.parse(text);
                    results = Array.isArray(parsed) ? parsed : [];
                } catch (e) {
                    results = [];
                }

                const options = results.map(item => ({
                    id: item.id,
                    score: root.scoreResult(item),
                    trackName: item.trackName ?? "",
                    artistName: item.artistName ?? "",
                    duration: item.duration ?? 0,
                    instrumental: item.instrumental ?? false,
                    lines: root.parseSyncedLyrics(item.syncedLyrics)
                })).filter(option => Number.isFinite(option.score)).sort((a, b) => b.score - a.score).slice(0, root.maxResults);

                // An exact title+artist search misses remasters and translated
                // titles; retry once with the looser free-text endpoint.
                if (options.length === 0 && !fetcher.usedFreeTextSearch) {
                    root.fetch(true);
                    return;
                }

                root.options = options;
                root.loading = false;
                root.error = options.length === 0 ? Translation.tr("No synced lyrics") : "";
            }
        }
    }

    Component.onCompleted: root.loadSelection()
}
