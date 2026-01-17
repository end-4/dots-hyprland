pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool levenshteinSearch: Config.options?.search.levenshtein ?? false
    property bool frecencySearch: Config.options?.search.frecency ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
            "code-url-handler": "visual-studio-code",
            "Code": "visual-studio-code",
            "gnome-tweaks": "org.gnome.tweaks",
            "pavucontrol-qt": "pavucontrol",
            "wps": "wps-office2019-kprometheus",
            "wpsoffice": "wps-office2019-kprometheus",
            "footclient": "foot"
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
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values).filter((app, index, self) => index === self.findIndex(t => (t.id === app.id)))

    readonly property var preppedNames: list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
            }))

    readonly property var preppedIcons: list.map(a => ({
                name: Fuzzy.prepare(`${a.icon} `),
                entry: a
            }))

    /**
     * Get initials/acronym from an app name
     * e.g., "Visual Studio Code" -> "vsc", "Discord" -> "d", "System Settings" -> "ss"
     */
    function getInitials(name: string): string {
        // Split on spaces, hyphens, and underscores, get first letter of each word
        const words = name.split(/[\s\-_]+/);
        return words.map(w => w.charAt(0).toLowerCase()).join('');
    }

    /**
     * Check if search matches the beginning of the name (prefix match)
     */
    function isPrefixMatch(name: string, search: string): bool {
        return name.toLowerCase().startsWith(search.toLowerCase());
    }

    /**
     * Get match score using either Levenshtein or Fuzzy algorithm
     * Includes prefix/acronym matching boost
     */
    function getMatchScore(appName: string, search: string): real {
        const searchLower = search.toLowerCase();
        const nameLower = appName.toLowerCase();

        // Check for prefix match (e.g., "di" matches "Discord")
        // This is the most important match type for user intent
        const prefixMatch = nameLower.startsWith(searchLower);

        // Check for acronym match (e.g., "vsc" matches "Visual Studio Code")
        const initials = getInitials(appName);
        const acronymMatch = initials.startsWith(searchLower);

        // Get base score from fuzzy or levenshtein
        let baseScore;
        if (root.levenshteinSearch) {
            baseScore = Levendist.computeScore(nameLower, searchLower);
        } else {
            const prepped = preppedNames.find(p => p.entry.name === appName);
            const fuzzyResult = Fuzzy.single(search, prepped?.name);
            baseScore = fuzzyResult?.score ?? 0;
        }

        // Apply boosts - prefix match is highest priority
        if (prefixMatch) {
            // Prefix match gets near-perfect score to override frecency
            // Shorter names that match get slightly higher scores
            const lengthBonus = 0.05 * (1 - Math.min(nameLower.length, 20) / 20);
            return 0.95 + lengthBonus;
        } else if (acronymMatch) {
            // Acronym match gets high score
            return Math.max(baseScore, 0.85);
        }

        return baseScore;
    }

    function fuzzyQuery(search: string): var {
        // Empty search with frecency: show most used apps
        if (search === "" && root.frecencySearch) {
            return list.map(obj => ({
                        entry: obj,
                        score: AppUsage.getScore(obj.id)
                    })).filter(item => item.score > 0).sort((a, b) => b.score - a.score).map(item => item.entry);
        }

        // Empty search without frecency: return empty
        if (search === "") {
            return [];
        }

        // Frecency mode: combine match score with usage frequency
        if (root.frecencySearch) {
            // Dynamic weighting based on query length
            const queryLen = search.length;
            let matchWeight, usageWeight;
            if (queryLen <= 2) {
                matchWeight = 0.3;
                usageWeight = 0.7;
            } else if (queryLen === 3) {
                matchWeight = 0.5;
                usageWeight = 0.5;
            } else {
                matchWeight = 0.7;
                usageWeight = 0.3;
            }

            const searchLower = search.toLowerCase();
            const results = list.map(obj => {
                const matchScore = getMatchScore(obj.name, search);
                const usageScore = AppUsage.getScore(obj.id);
                let combinedScore = matchScore * matchWeight + usageScore * usageWeight;

                // Prefix match boost - apps starting with search always rank highest
                if (obj.name.toLowerCase().startsWith(searchLower)) {
                    combinedScore = 2.0 + combinedScore; // Guaranteed to be higher than any non-prefix match
                } else
                // Acronym match boost
                if (getInitials(obj.name).startsWith(searchLower)) {
                    combinedScore = 1.5 + combinedScore;
                }

                return {
                    entry: obj,
                    matchScore: matchScore,
                    usageScore: usageScore,
                    combinedScore: combinedScore
                };
            }).filter(item => item.matchScore > root.scoreThreshold).sort((a, b) => b.combinedScore - a.combinedScore).map(item => item.entry);

            return results;
        }

        // Levenshtein mode (without frecency)
        if (root.levenshteinSearch) {
            const results = list.map(obj => ({
                        entry: obj,
                        score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
                    })).filter(item => item.score > root.scoreThreshold).sort((a, b) => b.score - a.score);
            return results.map(item => item.entry);
        }

        // Default: fuzzy sort
        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry;
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0)
            return false;
        return (Quickshell.iconPath(iconName, true).length > 0) && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0];
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0)
            return "image-missing";

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry)
            return entry.icon;

        // Normal substitutions
        if (substitutions[str])
            return substitutions[str];
        if (substitutions[str.toLowerCase()])
            return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(substitution.regex, substitution.replace);
            if (replacedName != str)
                return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str))
            return str;

        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased))
            return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName))
            return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName))
            return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess))
            return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess))
            return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry;
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon;
            if (iconExists(guess))
                return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon;
            if (iconExists(guess))
                return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry)
            return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
