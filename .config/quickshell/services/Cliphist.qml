pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common"
import "root:/"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property list<string> entries: []
    property string highlightPrefix: `<b><font color="${Appearance.m3colors.m3primary}">`
    property string highlightSuffix: `</font></b>`
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
            // console.log(JSON.stringify(r))
            // return r.highlight(highlightPrefix, highlightSuffix);
        });
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = false
        readProc.running = true
    }

    Process {
        id: readProc
        property list<string> buffer: []
        
        command: ["cliphist", "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus)
            }
        }
    }
}
