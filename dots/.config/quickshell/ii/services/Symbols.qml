pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Symbols (special characters, Greek letters, math symbols, etc.).
 */
Singleton {
    id: root
    property string symbolsScriptPath: `${Directories.config}/hypr/hyprland/scripts/fuzzel-symbols.sh`
    property string lineBeforeData: "### DATA ###"
    property list<var> list
    readonly property var preparedEntries: list.map(a => ({
        name: Fuzzy.prepare(`${a}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function load() {
        symbolsFileView.reload()
    }

    function updateSymbols(fileContent) {
        const lines = fileContent.split("\n")
        const dataIndex = lines.indexOf(root.lineBeforeData)
        if (dataIndex === -1) {
            console.warn("No data section found in symbols script file.")
            return
        }
        const symbols = lines.slice(dataIndex + 1).filter(line => line.trim() !== "")
        root.list = symbols.map(line => line.trim())
    }

    FileView {
        id: symbolsFileView
        path: Qt.resolvedUrl(root.symbolsScriptPath)
        onLoadedChanged: {
            const fileContent = symbolsFileView.text()
            root.updateSymbols(fileContent)
        }
    }
}
