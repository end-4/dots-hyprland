pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.ii.island

// Clipboard watcher. Copied images become a card (Open / Save); copied text flashes a short preview,
// or a lock with only the length when it looks like a secret. wl-paste --watch reports every copy,
// screenshots included (end-4 puts them on the clipboard).
Item {
    id: root

    // Config.options.bar.island.clipboard
    readonly property bool clipOn: IslandConfig.clipboard

    onClipOnChanged: root.syncWatchers()

    // Image temp files this provider wrote, oldest first. Only the newest few are kept on disk.
    property var kept: []
    readonly property int keepCount: 5
    // Copied images can be private: keep them in the user-only runtime dir, not world-readable /tmp.
    readonly property string imageDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ii-island"
    readonly property string imagePattern: root.imageDir + "/clip-"

    // wl-paste --watch replays the current clipboard right after it starts. Events in this window are
    // that replay, so they are dropped. (The window, not "first event", because wl-paste --type image
    // emits nothing at start when the clipboard holds no image, and a literal first-event skip would
    // drop the first real copy.)
    readonly property int replayMs: 2000
    // A text event right after an image copy is the same copy (apps offer text alongside images).
    readonly property int imageGapMs: 400
    property double lastImageAt: 0
    property double imageStartedAt: 0
    property double textStartedAt: 0

    function syncWatchers() {
        if (!root.clipOn) {
            imageWatch.running = false;
            textWatch.running = false;
            return;
        }
        if (!imageWatch.running) {
            root.imageStartedAt = Date.now();
            imageWatch.running = true;
        }
        if (!textWatch.running) {
            root.textStartedAt = Date.now();
            textWatch.running = true;
        }
    }

    // Watchers exit when wl-paste dies (session restart, compositor hiccup): retry slowly, not in a loop.
    function restartLater() {
        if (root.clipOn)
            restartTimer.restart();
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: root.syncWatchers()
    }

    function discard(path) {
        Quickshell.execDetached(["rm", "-f", "--", path]);
    }

    function keepImage(path) {
        root.kept.push(path);
        while (root.kept.length > root.keepCount)
            root.discard(root.kept.shift());
    }

    function onImage(path) {
        // Only our own temp files are touched; anything else on the line is ignored.
        if (!path.startsWith(root.imagePattern))
            return;
        root.lastImageAt = Date.now();
        if (Date.now() - root.imageStartedAt < root.replayMs) {
            root.discard(path);
            return;
        }
        root.keepImage(path);
        IslandState.pushCard("clip", {
            icon: "image",
            title: Translation.tr("Copied image"),
            body: "",
            image: path,
            ttl: 5000,
            actions: [
                { text: Translation.tr("Open"), command: ["xdg-open", path] },
                { text: Translation.tr("Save"), command: ["sh", "-c", "mkdir -p ~/Pictures/Screenshots && cp \"$0\" ~/Pictures/Screenshots/", path] }
            ]
        });
    }

    // Passwords and tokens: no spaces, 8-128 chars, at least 3 character classes, or a known token shape.
    function looksSecret(t) {
        if (/\s/.test(t))
            return false;
        if (/^(ghp_|sk-|xox|AKIA)/.test(t))
            return true;
        if (/^[A-Za-z0-9+\/=_-]{32,}$/.test(t))
            return true;
        if (t.length < 8 || t.length > 128)
            return false;
        let classes = 0;
        if (/[a-z]/.test(t)) classes++;
        if (/[A-Z]/.test(t)) classes++;
        if (/[0-9]/.test(t)) classes++;
        if (/[^A-Za-z0-9]/.test(t)) classes++;
        return classes >= 3;
    }

    // One line: "<mime list>\t<text preview>". The preview is at most 200 bytes, newlines flattened.
    function onText(line) {
        const tab = line.indexOf("\t");
        if (tab < 0)
            return;
        const mimes = line.slice(0, tab);
        const text = line.slice(tab + 1).trim();
        const now = Date.now();
        if (now - root.textStartedAt < root.replayMs || now - root.lastImageAt < root.imageGapMs)
            return;
        // KeePassXC (and other managers) mark secrets with this type: show nothing at all.
        if (mimes.indexOf("x-kde-passwordManagerHint") >= 0 || text === "")
            return;
        // Never show copied text itself (passphrases with spaces would slip past any
        // "looks like a password" check). Links show only their domain.
        const url = text.match(/^https?:\/\/([^\/\s?#]+)/i);
        if (url)
            IslandState.flash("link", url[1].replace(/^www\./, ""), { ms: 1400 });
        else
            IslandState.flash(root.looksSecret(text) ? "lock" : "content_copy", Translation.tr("Copied · %1 chars").arg(text.length), { ms: 1400 });
    }

    Component.onCompleted: {
        // Drop image files left by earlier shell sessions, keeping the newest few.
        Quickshell.execDetached(["sh", "-c", "ls -1t \"$0\"/clip-*.png 2>/dev/null | tail -n +6 | xargs -r rm -f --", root.imageDir]);
        root.syncWatchers();
    }

    Process {
        id: imageWatch
        // The script runs once per copy with the image on stdin; it prints the path it wrote.
        // Some sources offer an image but send no bytes: those are dropped, so no empty card.
        command: ["wl-paste", "--type", "image", "--watch", "sh", "-c", 'mkdir -p -m 700 "$0"; f="$0/clip-$(date +%s%N).png"; cat > "$f"; if [ -s "$f" ]; then echo "$f"; else rm -f "$f"; fi', root.imageDir]
        stdout: SplitParser {
            onRead: data => root.onImage(data.trim())
        }
        onExited: root.restartLater()
    }

    Process {
        id: textWatch
        // Prints the MIME list, a tab, then the first 200 bytes of text on one line (newlines/tabs flattened).
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", 'types=$(wl-paste --list-types 2>/dev/null | tr "\\n" " "); printf "%s\\t" "$types"; head -c 200 | tr "\\n\\t" "  "; echo']
        stdout: SplitParser {
            onRead: data => root.onText(data)
        }
        onExited: root.restartLater()
    }
}
