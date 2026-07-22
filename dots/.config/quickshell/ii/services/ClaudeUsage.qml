pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Claude subscription usage (Pro / Max).
 *
 * Reads the OAuth access token from ~/.claude/.credentials.json (kept fresh by
 * Claude Code) and polls https://api.anthropic.com/api/oauth/usage — the same
 * data Claude Code's /usage command shows. Only active when
 * Config.options.bar.claudeUsage.enable is true.
 *
 * Requires `jq` and `curl` (already used elsewhere in the shell).
 */
Singleton {
    id: root

    readonly property bool enabled: Config.options.bar.claudeUsage.enable
    readonly property int fetchInterval: Config.options.bar.claudeUsage.fetchInterval * 60 * 1000

    property bool available: false
    property string lastError: ""
    property string subscriptionType: "" // "pro" | "max" | ...

    // Utilization percentages (0-100); -1 means "not reported by the API"
    property real fiveHour: 0
    property real sevenDay: 0
    property real sevenDayOpus: -1
    property real sevenDaySonnet: -1

    // Reset timestamps (epoch ms; 0 if unknown)
    property double fiveHourReset: 0
    property double sevenDayReset: 0

    // Pay-as-you-go extra credits
    property bool extraEnabled: false
    property real extraUsedCredits: 0
    property real extraMonthlyLimit: 0
    property string extraCurrency: ""

    function _pct(v) {
        return (v === null || v === undefined) ? -1 : v;
    }

    function _parseIso(s) {
        if (!s)
            return 0;
        const t = Date.parse(s);
        return isNaN(t) ? 0 : t;
    }

    // Human "2h 5m" until the given epoch-ms. References DateTime.time so it
    // recomputes on the clock tick.
    function timeUntil(epochMs) {
        DateTime.time; // reactivity dependency
        if (!epochMs)
            return "—";
        let diff = Math.floor((epochMs - Date.now()) / 1000);
        if (diff <= 0)
            return Translation.tr("now");
        const d = Math.floor(diff / 86400);
        diff %= 86400;
        const h = Math.floor(diff / 3600);
        diff %= 3600;
        const m = Math.floor(diff / 60);
        let out = "";
        if (d > 0)
            out += `${d}d `;
        if (h > 0)
            out += `${h}h `;
        out += `${m}m`;
        return out.trim();
    }

    function refine(data) {
        root.subscriptionType = data.subscriptionType ?? "";
        root.fiveHour = data.five_hour?.utilization ?? 0;
        root.sevenDay = data.seven_day?.utilization ?? 0;
        root.sevenDayOpus = root._pct(data.seven_day_opus?.utilization);
        root.sevenDaySonnet = root._pct(data.seven_day_sonnet?.utilization);
        root.fiveHourReset = root._parseIso(data.five_hour?.resets_at);
        root.sevenDayReset = root._parseIso(data.seven_day?.resets_at);
        const ex = data.extra_usage;
        root.extraEnabled = ex?.is_enabled ?? false;
        root.extraUsedCredits = ex?.used_credits ?? 0;
        root.extraMonthlyLimit = ex?.monthly_limit ?? 0;
        root.extraCurrency = ex?.currency ?? "";
        root.available = true;
        root.lastError = "";
    }

    function getData() {
        if (!root.enabled)
            return;
        fetcher.running = false;
        fetcher.running = true;
    }

    Process {
        id: fetcher
        command: ["bash", "-c", "creds=\"$HOME/.claude/.credentials.json\"; " + "tok=$(jq -r '.claudeAiOauth.accessToken' \"$creds\" 2>/dev/null); " + "sub=$(jq -r '.claudeAiOauth.subscriptionType' \"$creds\" 2>/dev/null); " + "if [ -z \"$tok\" ] || [ \"$tok\" = null ]; then echo '{\"error\":\"no Claude token\"}'; exit 0; fi; " + "curl -s --max-time 10 " + "-H \"Authorization: Bearer $tok\" " + "-H \"anthropic-beta: oauth-2025-04-20\" " + "-H \"anthropic-version: 2023-06-01\" " + "https://api.anthropic.com/api/oauth/usage " + "| jq -c --arg sub \"$sub\" '. + {subscriptionType:$sub}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) {
                    root.available = false;
                    root.lastError = "empty response";
                    retryTimer.restart();
                    return;
                }
                try {
                    const d = JSON.parse(text);
                    if (d.error) {
                        root.available = false;
                        root.lastError = String(d.error);
                        retryTimer.restart();
                        return;
                    }
                    root.refine(d);
                } catch (e) {
                    root.available = false;
                    root.lastError = e.message;
                    retryTimer.restart();
                    console.error(`[ClaudeUsage] ${e.message}: ${text}`);
                }
            }
        }
    }

    Timer {
        running: root.enabled
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.getData()
    }

    // Quick retry while we don't have data yet (cold start / token mid-refresh /
    // transient network), so a failed first fetch doesn't leave "Unavailable"
    // showing until the next full interval.
    Timer {
        id: retryTimer
        interval: 15000
        repeat: false
        onTriggered: if (root.enabled && !root.available) root.getData()
    }
}
