pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string homeDir: (Quickshell.env("HOME") || "/home").replace(/\/$/, "")
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (homeDir + "/.cache")) + "/everything"
    readonly property string dbPath: cacheDir + "/plocate.db"
    readonly property string updateScript: Quickshell.shellPath("scripts/everything-update.sh")
    readonly property string queryScript: Quickshell.shellPath("scripts/everything-query.py")

    property string sortBy: "relevance"   // relevance | name | size | type | mtime
    property string sortOrder: "desc"     // asc | desc
    property string filterType: "all"     // all | dir | file | image | video | audio | doc | archive | exec | code
    property bool sortMenuOpen: false
    property bool filterMenuOpen: false

    property string pendingQuery: ""
    property string lastCompletedSignature: ""
    property list<var> results: []
    property bool indexingStarted: false

    function ensureIndex() {
        if (root.indexingStarted)
            return;
        root.indexingStarted = true;
        ensureProc.running = true;
    }

    function setSort(field: string) {
        if (root.sortBy === field) {
            root.sortOrder = (root.sortOrder === "desc") ? "asc" : "desc";
        } else {
            root.sortBy = field;
            root.sortOrder = (field === "name" || field === "type") ? "asc" : "desc";
        }
        if (root.pendingQuery !== "")
            debounceTimer.restart();
    }

    function setFilter(ftype: string) {
        if (root.filterType === ftype)
            return;
        root.filterType = ftype;
        if (root.pendingQuery !== "")
            debounceTimer.restart();
    }

    function currentSignature(q: string): string {
        return q + "|" + root.sortBy + "|" + root.sortOrder + "|" + root.filterType;
    }

    function updateQuery(rawQuery: string) {
        const q = (rawQuery ?? "").trim();
        const sig = root.currentSignature(q);
        if (q === root.pendingQuery && (sig === root.lastCompletedSignature || searchProc.running || debounceTimer.running))
            return;
        root.pendingQuery = q;
        if (q === "") {
            debounceTimer.stop();
            return;
        }
        debounceTimer.restart();
    }

    function openFile(path: string) {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openFolder(path: string) {
        const idx = path.lastIndexOf("/");
        const dir = idx > 0 ? path.slice(0, idx) : "/";
        Quickshell.execDetached(["xdg-open", dir]);
    }

    function copyPath(path: string) {
        Quickshell.clipboardText = path;
    }

    function runSearch() {
        const q = root.pendingQuery;
        if (q === "")
            return;
        const terms = q.split(/\s+/).filter(Boolean);
        if (terms.length === 0)
            return;

        searchProc.running = false;
        searchProc.sigAtLaunch = root.currentSignature(q);
        searchProc.buffer = [];
        searchProc.command = [
            "python3", root.queryScript,
            root.dbPath, root.updateScript,
            root.sortBy, root.sortOrder, root.filterType,
            ...terms
        ];
        searchProc.running = true;
    }

    Timer {
        id: debounceTimer
        interval: 35
        onTriggered: root.runSearch()
    }

    Process {
        id: ensureProc
        command: ["bash", "-c", "[ -s \"$1\" ] || { [ -x \"$2\" ] && \"$2\"; }", "_", root.dbPath, root.updateScript]
    }

    Process {
        id: searchProc
        property string sigAtLaunch: ""
        property list<var> buffer: []

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.length === 0)
                    return;
                try {
                    searchProc.buffer.push(JSON.parse(data));
                } catch (e) {}
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.lastCompletedSignature = searchProc.sigAtLaunch;
            root.results = searchProc.buffer;
            if (root.pendingQuery !== "" && root.currentSignature(root.pendingQuery) !== searchProc.sigAtLaunch)
                debounceTimer.restart();
        }
    }
}
