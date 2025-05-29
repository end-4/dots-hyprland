pragma Singleton

import "root:/modules/common"
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/levendist.js" as Levendist
import Quickshell
import Quickshell.Io

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name with normalization, possibly with desktop entry searching later
 */
Singleton {
    id: root
    property bool sloppySearch: ConfigOptions?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "GitHub Desktop": "github-desktop",
        "Minecraft* 1.20.1": "minecraft",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
        "": "image-missing"
    })
    property var regexSubstitutions: [
        {
            "regex": "/^steam_app_(\\d+)$/",
            "replace": "steam_icon_$1"
        }
    ]

    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
            }))

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
        return Quickshell.iconPath(iconName, true).length > 0;
    }

    function guessIcon(str) {
        if (!str) return "image-missing";

        // Normal substitutions
        if (substitutions[str])
            return substitutions[str];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // If it gets detected normally, no need to guess
        if (iconExists(str)) return str;

        let guessStr = str;
        // Guess: Take only app name of reverse domain name notation
        guessStr = str.split('.').slice(-1)[0].toLowerCase();
        if (iconExists(guessStr)) return guessStr;
        // Guess: normalize to kebab case
        guessStr = str.toLowerCase().replace(/\s+/g, "-");
        if (iconExists(guessStr)) return guessStr;

        // Give up
        return str;
    }
}
