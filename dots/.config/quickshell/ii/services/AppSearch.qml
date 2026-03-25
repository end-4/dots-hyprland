pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications
 * - Modes: Exact (name only), Normal (name + genericName + comment), Sloppy (+ keywords, categories)
 * - Levenshtein toggle applies to all modes
 */
Singleton {
    id: root
    readonly property string searchMode: Config.options?.search?.mode ?? "exact"
    readonly property bool useLevenshtein: Config.options?.search?.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol": "pavucontrol-qt",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Deduped list to fix double icons
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .filter((app, index, self) => 
            index === self.findIndex((t) => (
                t.id === app.id
            ))
    )

    /** Normal scope: name + genericName + comment only */
    function searchableTextNormal(entry) {
        const parts = [
            entry.name || "",
            entry.genericName || "",
            entry.comment || ""
        ];
        return parts.filter(Boolean).join(" ");
    }

    /** Sloppy scope: name + comment + genericName + keywords + categories */
    function searchableText(entry) {
        const parts = [
            entry.name || "",
            entry.comment || "",
            entry.genericName || "",
            (entry.keywords || []).join(" "),
            (entry.categories || []).join(" ")
        ];
        return parts.filter(Boolean).join(" ");
    }
    
    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedSearchTextNormal: list.map(a => ({
        name: Fuzzy.prepare(searchableTextNormal(a) + " "),
        entry: a
    }))

    readonly property var preppedSearchText: list.map(a => ({
        name: Fuzzy.prepare(searchableText(a) + " "),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    function normalizeSearchTerm(search) {
        return (search || "").trim().toLowerCase();
    }

    function exactMatchScore(entry, normalizedSearch) {
        if (!normalizedSearch)
            return 0;

        const name = (entry.name || "").trim().toLowerCase();
        const genericName = (entry.genericName || "").trim().toLowerCase();
        if (name === normalizedSearch)
            return 3;
        if (genericName === normalizedSearch)
            return 2;
        if (name.startsWith(normalizedSearch))
            return 1;
        return 0;
    }

    function prioritizeExactMatches(search, entries) {
        const normalizedSearch = normalizeSearchTerm(search);
        if (!normalizedSearch || !entries || entries.length <= 1)
            return entries;

        return entries
            .map((entry, index) => ({
                entry: entry,
                index: index,
                score: exactMatchScore(entry, normalizedSearch)
            }))
            .sort((a, b) => {
                if (a.score !== b.score)
                    return b.score - a.score;
                return a.index - b.index;
            })
            .map(item => item.entry);
    }

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        const mode = root.searchMode;
        const useLev = root.useLevenshtein;

        function runLevenshtein(getText) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(getText(obj).toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results.map(item => item.entry)
        }

        function runFuzzy(prepped, useConfigThreshold) {
            const opts = { all: true, key: "name" };
            if (useConfigThreshold) {
                const t = (Config.options?.search?.fuzzyThreshold ?? 25) / 100;
                if (t > 0) opts.threshold = t;
            }
            return Fuzzy.go(search, prepped, opts).map(r => r.obj.entry)
        }

        // Exact: name only (no threshold)
        if (mode === "exact") {
            const matches = useLev ? runLevenshtein(e => e.name) : runFuzzy(preppedNames, false);
            return prioritizeExactMatches(search, matches);
        }
        // Normal: name + genericName + comment, use fuzzy threshold to avoid false positives
        if (mode === "normal") {
            const matches = useLev ? runLevenshtein(searchableTextNormal) : runFuzzy(preppedSearchTextNormal, true);
            return prioritizeExactMatches(search, matches);
        }
        // Sloppy: name + comment + genericName + keywords + categories
        const matches = useLev ? runLevenshtein(searchableText) : runFuzzy(preppedSearchText, true);
        return prioritizeExactMatches(search, matches);
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
