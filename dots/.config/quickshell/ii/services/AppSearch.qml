pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import QtQuick 2.15

/**
 * - Eases fuzzy searching for applications by name
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

    // Cache
    property var _iconCache: ({})
    property var list: []
    property var preppedNames: []
    property var preppedIcons: []

    // Debounce Application Re-indexing
    Timer {
        id: reindexTimer
        interval: 300
        repeat: false
        onTriggered: root.rebuildIndex()
    }

    Connections {
        target: DesktopEntries.applications

        // Restart timer when desktop values changes
        function onValuesChanged(){
            reindexTimer.restart()
        }
    }

    Component.onCompleted: {
        root.rebuildIndex()
    }

    // Icon cache
    property var _iconCache: ({})

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
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

        // First check the icon cache
        if (_iconCache[str] !== undefined) {
            return _iconCache[str];
        }

        let res = (function(){
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
        })();

        // Save it to cache and return
        _iconCache[str] = res;
        return res;
    }

    function rebuildIndex() {
        const rawApps = DesktopEntries.applications.values;
        if (!rawApps) return;

        // Optimize Deduplication Complexity
        const seenIds = new Set();
        const dedupedList = [];
        for (let i = 0; i < rawApps.length; i++) {
            const app = rawApps[i];
            if (app && app.id && !seenIds.has(app.id)) {
                seenIds.add(app.id);
                dedupedList.push(app);
            }
        }
        root.list = dedupedList;

        root.preppedNames = dedupedList.map(a => ({
            name: Fuzzy.prepare(`${a.name} `),
            id: Fuzzy.prepare(`${a.id} `),
            extra: Fuzzy.prepare(`${a.genericName ?? ""} ${a.comment ?? ""} ${(a.keywords ?? []).join(" ")} `),
            merged: `${a.name} ${a.id} ${a.genericName ?? ""} ${a.comment ?? ""} ${(a.keywords ?? []).join(" ")}`.toLowerCase(),
            entry: a
        }));

        root.preppedIcons = dedupedList.map(a => ({
            name: Fuzzy.prepare(`${a.icon} `),
            entry: a
        }));
    }

}
