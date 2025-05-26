pragma Singleton

import "root:/modules/common"
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/levendist.js" as Levendist
import Quickshell
import Quickshell.Io

/**
 * Eases searching for applications by name.
 */
Singleton {
    id: root
    property bool sloppySearch: ConfigOptions?.search.sloppy ?? false
    property real scoreThreshold: 0.2

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
}
