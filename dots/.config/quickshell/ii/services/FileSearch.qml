pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
	id: root

	property var results: []
	property string pendingQuery: ""
	property string activeQuery: ""
	property int searchId: 0
	property bool running: false

	function normalizePath(path) {
		if (!path) return "";
		let normalized = FileUtils.trimFileProtocol(String(path)).trim();
		if (normalized.startsWith("~/")) {
			normalized = FileUtils.trimFileProtocol(Directories.home) + normalized.slice(1);
		}
		if (normalized.endsWith("/")) {
			normalized = normalized.slice(0, -1);
		}
		return normalized;
	}

	function isExcluded(path) {
    if (Config.options.search.fileSearch.excludeHiddenDirs) {
        // Match any hidden dir segment: "/.name/" or ending "/.name"
        if (path.match(/\/\.[^/]+(\/|$)/)) {
            return true;
        }
    }

    const exclude = Config.options.search.fileSearch.exclude;
    if (!exclude || exclude.length === 0) return false;
    for (let i = 0; i < exclude.length; i++) {
        const needle = String(exclude[i]).trim();
        if (needle.length === 0) continue;
        if (path.includes(`/${needle}/`) || path.endsWith(`/${needle}`)) {
            return true;
        }
    }
    return false;
}

	function isAllowedByPath(path) {
		const paths = Config.options.search.fileSearch.paths;
		if (!paths || paths.length === 0) return true;
		for (let i = 0; i < paths.length; i++) {
			const base = normalizePath(paths[i]);
			if (!base) continue;
			if (path === base || path.startsWith(base + "/")) {
				return true;
			}
		}
		return false;
	}

	function shouldSearch(query) {
		if (!Config.options.search.fileSearch.enable) return false;
		if (!query || query.trim().length < 2) return false;
		return true;
	}

	function reset() {
		results = [];
		activeQuery = "";
		if (plocateProc.running) {
			plocateProc.running = false;
		}
	}

	function search(query) {
		pendingQuery = String(query || "").trim();
		if (!shouldSearch(pendingQuery)) {
			reset();
			return;
		}
		debounceTimer.restart();
	}

	Timer {
		id: debounceTimer
		interval: 200
		repeat: false
		onTriggered: {
			root.runSearch(pendingQuery);
		}
	}

	function runSearch(query) {
    const trimmed = String(query || "").trim();
    if (!shouldSearch(trimmed)) { reset(); return; }
    if (plocateProc.running) plocateProc.running = false;

    searchId += 1;
    activeQuery = trimmed;
    results = [];

    const maxResults = Config.options.search.fileSearch.maxResults;

    // Tag each line with d: or f: prefix
    const command = [
        "bash", "-c",
        `plocate -i --basename --limit ${maxResults} '${trimmed}' | while IFS= read -r p; do [ -d "$p" ] && printf 'd:%s\n' "$p" || printf 'f:%s\n' "$p"; done`
    ];

    plocateProc.runId = searchId;
    plocateProc.accepted = 0;
    plocateProc.command = command;
    plocateProc.running = true;
    root.running = true;
}

	Process {
		id: plocateProc
		property int runId: 0
		property int accepted: 0

		stdout: SplitParser {
			onRead: line => {
    if (plocateProc.runId !== root.searchId) return;
    const raw = String(line || "").trim();
    if (!raw || raw.length < 3) return;

    const isDir = raw.startsWith("d:");
    const rawPath = raw.slice(2);

    const normalized = root.normalizePath(rawPath);
    if (!normalized) return;
    if (!root.isAllowedByPath(normalized)) return;
    if (root.isExcluded(normalized)) return;
    if (plocateProc.accepted >= Config.options.search.fileSearch.maxResults) {
        plocateProc.running = false;
        return;
    }

    plocateProc.accepted += 1;
    root.results = root.results.concat([{ path: normalized, isDir: isDir }]);
}
		}

		stderr: SplitParser {
			onRead: line => {
				if (plocateProc.runId !== root.searchId) return;
			}
		}

		onExited: (exitCode, exitStatus) => {
			if (plocateProc.runId !== root.searchId) return;
			root.running = false;
		}
	}
}
