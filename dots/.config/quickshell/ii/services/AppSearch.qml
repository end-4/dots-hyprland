pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name and keywords
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
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
        .filter((app, index, self) => index === self.findIndex(t => t.id === app.id))
   
    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    readonly property var searchEntries: list.map(app => ({
        namePrepared: Fuzzy.prepare(app.name),
        keywordsPrepared: Fuzzy.prepare(app.keywords ? app.keywords.join(' ') : ''),
        genericNamePrepared: Fuzzy.prepare(app.genericName || ''),
        entry: app
    }))

    function computeScoreForQuery(query, target) {
        if (!target) return 0;
        return Levendist.computeScore(target.toLowerCase(), query.toLowerCase());
    }

    function simpleMatch(search, str) {
        if (!str) return false;
        return str.toLowerCase().indexOf(search.toLowerCase()) !== -1;
    }

    function fuzzyQuery(search) {
        if (!search || search.length === 0) return [];

        if (root.sloppySearch) {
            const lowerSearch = search.toLowerCase();
            const results = [];
            for (let i = 0; i < list.length; i++) {
                const app = list[i];
                let bestScore = computeScoreForQuery(lowerSearch, app.name);
                if (app.keywords) {
                    for (let k = 0; k < app.keywords.length; k++) {
                        const kwScore = computeScoreForQuery(lowerSearch, app.keywords[k]);
                        if (kwScore > bestScore) bestScore = kwScore;
                    }
                }
                const genericScore = computeScoreForQuery(lowerSearch, app.genericName);
                if (genericScore > bestScore) bestScore = genericScore;
                
                if (bestScore > root.scoreThreshold) {
                    results.push({ entry: app, score: bestScore });
                }
            }
            results.sort((a, b) => b.score - a.score);
            return results.map(item => item.entry);
        }

        const results = Fuzzy.go(search, root.searchEntries, {
            all: true,
            keys: ['namePrepared', 'keywordsPrepared', 'genericNamePrepared'],
            scoreFn: (matchResults) => {
                let total = 0;
                let count = 0;
                for (let i = 0; i < matchResults.length; i++) {
                    if (matchResults[i] && matchResults[i].score > 0) {
                        total += matchResults[i].score * (i === 0 ? 1.0 : 0.8);
                        count++;
                    }
                }
                return count ? total / count : 0;
            }
        });

        return results && results.length ? results.map(r => r.obj.entry) : [];
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
