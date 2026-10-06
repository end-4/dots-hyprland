pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root
    // Polling interval, derived from Config defaults (minutes -> ms).
    // Falls back to 5 minutes so a missing/partial config entry cannot yield an invalid interval.
    readonly property int fetchInterval: Math.max(1, Config.options?.bar?.aiQuota?.intervalMinutes ?? 5) * 60 * 1000

    // Ordered list of provider ids we want to render, in display order.
    // Only providers actually present in the codexbar JSON are exposed.
    readonly property var providerOrder: ["codex", "claude"]

    // Friendly display name + real brand icon filename per provider id.
    readonly property var providerMeta: ({
        codex: { displayName: "Codex", iconSource: "openai-symbolic.svg" },
        claude: { displayName: "Claude", iconSource: "claude-symbolic.svg" }
    })

    // Normalized provider state, ordered by providerOrder and filtered to
    // providers present in the codexbar JSON. Each entry:
    //   { id, displayName, iconSource, hasError, errorMessage,
    //     primary, secondary, tertiary,  // each null or { usedPercent, resetsAt, windowMinutes }
    //     paceSummary, creditsRemaining }
    property var providers: []

    // The most relevant window for compact display: primary ?? secondary ?? tertiary.
    // null when the provider has no usage (error-only providers).
    function mainWindow(provider) {
        if (!provider) return null
        return provider.primary ?? provider.secondary ?? provider.tertiary ?? null
    }

    // Rounded percent for compact display, or -1 when there is no usable window.
    function mainPercent(provider) {
        const win = mainWindow(provider)
        return win ? Math.round(win.usedPercent) : -1
    }

    // Kick a fetch unless one is already in flight; the collector clears the flag on completion.
    property bool fetchInFlight: false

    function getData() {
        if (root.fetchInFlight)
            return
        root.fetchInFlight = true
        // Resolve the CLI through the user's login shell so PATH overrides and
        // ~/.local/bin survive session restarts; force non-interactive, machine output.
        // The timeout bounds slow provider probes (Claude's CLI probe takes ~20s) so a
        // hung fetch can never hold the in-flight guard and freeze later polls.
        fetcher.command[2] = 'timeout 90 codexbar --format json --json-only 2>/dev/null || true'
        fetcher.running = true
    }

    function refineData(rawProviders) {
        const byId = {}
        for (const raw of rawProviders) {
            if (!raw || !raw.provider) continue
            const meta = root.providerMeta[raw.provider] ?? { displayName: raw.provider, iconSource: "" }
            const usage = raw.usage ?? null
            const entry = {
                id: raw.provider,
                displayName: meta.displayName,
                iconSource: meta.iconSource,
                hasError: !!raw.error,
                errorMessage: raw.error?.message ?? "",
                primary: normalizeWindow(usage?.primary),
                secondary: normalizeWindow(usage?.secondary),
                tertiary: normalizeWindow(usage?.tertiary),
                paceSummary: raw.pace?.secondary?.summary ?? raw.pace?.primary?.summary ?? "",
                creditsRemaining: raw.credits?.remaining ?? 0
            }
            byId[raw.provider] = entry
        }
        const ordered = []
        for (const id of root.providerOrder) {
            if (byId[id]) ordered.push(byId[id])
        }
        root.providers = ordered
    }

    function normalizeWindow(win) {
        if (!win) return null
        return {
            usedPercent: typeof win.usedPercent === "number" ? win.usedPercent : 0,
            resetsAt: win.resetsAt ?? "",
            windowMinutes: typeof win.windowMinutes === "number" ? win.windowMinutes : 0
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-lc", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fetchInFlight = false
                if (text.length === 0)
                    return
                try {
                    const parsedData = JSON.parse(text)
                    if (!Array.isArray(parsedData)) {
                        console.error("[AiQuota] Expected a JSON array, got " + typeof parsedData)
                        return
                    }
                    root.refineData(parsedData)
                } catch (e) {
                    console.error(`[AiQuota] ${e.message}`)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Backstop so a crashed/killed process cannot wedge future polls.
            root.fetchInFlight = false
        }
    }

    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.getData()
    }
}
