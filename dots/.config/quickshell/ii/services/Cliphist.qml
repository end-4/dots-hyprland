pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property string cliphistFavDbArg: `-db-path ${Directories.favoriteClipboardPath}`
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    property list<string> favEntries: []
    readonly property var joinedEntries: {
        const favKeys = new Set(favEntries.map(e => StringUtils.cleanCliphistEntry(e)));
        const normal = entries
        .filter(e => !favKeys.has(StringUtils.cleanCliphistEntry(e)))
        .map(entry => ({ entry, isFav: false }));
        const favs = favEntries.map(entry => ({ entry, isFav: true }));
        return [...normal, ...favs];
    }
    readonly property var preparedEntries: joinedEntries.map(item => ({
        name: Fuzzy.prepare(item.entry.replace(/^\s*\S+\s+/, "")),
        entry: item.entry,
        isFav: item.isFav
    }))
    function joinEntries(): var {
        const pendingCleaned = favEntries.map(e => StringUtils.cleanCliphistEntry(e));
        const filteredEntries = entries
        .filter(entry => !pendingCleaned.includes(StringUtils.cleanCliphistEntry(entry)))
        .map(entry => ({ entry, isFav: false }));

        const favs = favEntries.map(entry => ({ entry, isFav: true }));

        return [...filteredEntries, ...favs];
    }
    function fuzzyQuery(search: string): var {
        const allEntries = joinEntries();
        if (search.trim() === "") {
            return allEntries;
        }
        if (search.trim() === "#fav")
            return favEntries.map(entry => ({ entry, isFav: true }));
        if (root.sloppySearch) {
            const results = allEntries.slice(0, 100).map(({ entry: str, isFav }) => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase()),
                isFav
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(({ entry, isFav }) => ({ entry, isFav }))
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return { entry: r.obj.entry, isFav: r.obj.isFav }
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy`]);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function copyFav(entry, fromDefault = false) {
        if (fromDefault) {
            const printfEntry = `printf '${StringUtils.shellSingleQuoteEscape(StringUtils.cleanCliphistEntry(entry))}'`
            Quickshell.execDetached(["bash", "-c", `${printfEntry} | ${root.cliphistBinary} ${root.cliphistFavDbArg} store && ${printfEntry} | wl-copy`]);
        }
        else if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} ${root.cliphistFavDbArg} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} ${root.cliphistFavDbArg} decode ${entryNumber} | wl-copy`]);
        }
    }

    function pasteFav(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} ${root.cliphistFavDbArg} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} ${root.cliphistFavDbArg} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function favToDefault(entry) {
        root.deleteFavEntry(entry);
        Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(StringUtils.cleanCliphistEntry(entry))}' | ${root.cliphistBinary} store`]);
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            if (favEntries.some(fEntry => StringUtils.cleanCliphistEntry(fEntry) === StringUtils.cleanCliphistEntry(entry))) return false;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`)
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: deleteFavProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteFavProc.entry)}' | ${root.cliphistBinary} ${root.cliphistFavDbArg} delete`]
        function deleteEntry(entry) {
            deleteFavProc.entry = entry;
            deleteFavProc.running = true;
            deleteFavProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteFavEntry(entry) {
        deleteFavProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart()
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: line => {
                readProc.buffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer;
                readFavProc.buffer = [];
                readFavProc.running = true;
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus);
            }
        }
    }

    Process {
        id: readFavProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "-db-path", Directories.favoriteClipboardPath, "list"]

        stdout: SplitParser {
            onRead: line => {
                readFavProc.buffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.favEntries = readFavProc.buffer;
            } else {
                console.error("[Cliphist] Failed to refresh favorite with code", exitCode, "and status", exitStatus);
            }
        }
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
