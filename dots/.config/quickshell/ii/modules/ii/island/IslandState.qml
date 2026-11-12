pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import qs.modules.ii.island
import "islandQueue.js" as Q

/**
 * Brain of the Dynamic Island: owns the event queue, listens to music,
 * notifications and Claude Code (via IPC), and exposes what to show.
 */
Singleton {
    id: root

    property var queue: Q.newState()
    property var main: null
    // Claude "working" status, shown in the bar, never dropped
    property var live: null
    property bool waiting: false // Claude is waiting for a permission answer
    // Opencode "working" status — parallel to Claude's live
    property var opencodeLive: null
    property bool opencodeWaiting: false // Opencode is waiting for a permission answer or a question
    // "working" | "permission" | "question" | "retry" | "compact" (meaningful while opencodeLive is set)
    property string opencodeState: "working"
    signal claudeBurst(string kind)
    signal opencodeBurst(string kind)
    property bool bubble: false
    property int extra: 0
    readonly property bool playing: MprisController.isPlaying
    property bool hoverOpen: false
    property string viewedArtUrl: "" // album art of the carousel card being looked at (blur background)
    // IPC openOverview/openToggles: the focused screen's island opens that card exactly like a
    // click would, so it closes the normal way (4 s, mouse leave, click outside).
    signal cardRequested(string kind)
    signal cardCloseRequested()

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? ""

    // Bar slot geometry per screen name, in bar-window coordinates: { x, y, width, height }
    property var slots: ({})

    function setSlot(name: string, x: real, y: real, w: real, h: real): void {
        const old = root.slots[name];
        if (old && old.x === x && old.y === y && old.width === w && old.height === h)
            return;
        const s = Object.assign({}, root.slots);
        s[name] = { x: x, y: y, width: w, height: h };
        root.slots = s;
    }

    function refreshView(): void {
        // Claude lives in the bar (logo), visible everywhere; it never drops a card.
        const live = root.queue.events.filter(e => e.kind === "claudeLive" || e.kind === "claudePerm");
        root.live = live.length > 0 ? live[live.length - 1] : null;
        root.waiting = root.queue.events.some(e => e.kind === "claudePerm");
        // Opencode: parallel live session (same priority as Claude).
        const ocLive = root.queue.events.filter(e => e.kind === "opencodeLive" || e.kind === "opencodePerm");
        root.opencodeLive = ocLive.length > 0 ? ocLive[ocLive.length - 1] : null;
        const ocPerm = root.queue.events.filter(e => e.kind === "opencodePerm");
        root.opencodeWaiting = ocPerm.length > 0;
        root.opencodeState = ocPerm.length > 0 ? (ocPerm[ocPerm.length - 1].payload.state ?? "permission")
            : (root.opencodeLive?.payload.state ?? "working");
        // Claude/Opencode events are excluded from the main notification stack.
        const v = Q.view({ events: root.queue.events.filter(e => {
            const k = e.kind;
            return !(k === "claudeLive" || k === "claudePerm" || k === "claudeDone" ||
                     k === "opencodeLive" || k === "opencodePerm" || k === "opencodeDone");
        }) }, root.playing);
        root.main = v.main;
        root.bubble = v.bubble;
        root.extra = v.extra;
    }

    function pushEvent(ev: var): void {
        root.queue = Q.push(root.queue, ev, Date.now());
        refreshView();
    }

    function dismiss(id: string): void {
        const ev = root.queue.events.find(e => e.id === id);
        root.queue = Q.remove(root.queue, id);
        if (ev && ev.kind === "notif")
            Notifications.timeoutNotification(ev.payload.notificationId);
        refreshView();
    }

    // Unread as the island shows it. end-4 only resets its counter when the right sidebar
    // opens, so clearing from the island left it > 0 (glow with nothing left). Cap it.
    readonly property int unread: Math.min(Notifications.unread, Notifications.list.length)

    // Clicking a notification (card or overview row): default action if it has one, then
    // it is gone from history too, instead of piling up there. If no default action,
    // try to focus the originating app window before discarding.
    function _focusAppWindow(appName: string): void {
        if (!appName || appName.length < 2) return;
        // Many apps report "Discord" but the window class is "discord", so compare without case.
        // Matched here and focused by address: Hyprland's dispatch runs Lua, and an app name
        // comes from whichever program sent the notification, so it must never reach that string.
        const name = appName.toLowerCase();
        const win = Hyprland.toplevels.values.find(t => (t.wayland?.appId ?? "").toLowerCase().includes(name));
        if (win)
            root.focusWindow("address:0x" + win.address);
    }

    function activateNotification(nid: int, eventId: string): void {
        if (eventId !== "") {
            root.queue = Q.remove(root.queue, eventId);
            refreshView();
        }
        const n = Notifications.list.find(x => x.notificationId === nid);
        if ((n?.actions ?? []).some(a => a.identifier === "default")) {
            Notifications.attemptInvokeAction(nid, "default");
        } else {
            // Try matching by app name against window class (most reliable on Wayland).
            _focusAppWindow(n?.appName ?? "");
            Qt.callLater(() => Notifications.discardNotification(nid));
        }
    }

    // Only pass selectors built from Hyprland's own values (pid, address), never outside text.
    function focusWindow(selector: string): void {
        Hyprland.dispatch(`hl.dsp.focus({ window = "${selector}" })`);
    }

    function focusPid(pid: int): void {
        if (pid > 0)
            root.focusWindow("pid:" + pid);
    }

    function handleClaude(msg: var): void {
        const sid = msg.sessionId;
        if (!sid)
            return;
        const payload = {
            cwd: msg.cwd ?? "",
            tool: msg.tool ?? "",
            detail: msg.detail ?? "",
            pid: msg.pid ?? -1,
            elapsedMs: msg.elapsedMs ?? 0,
            startedAt: Date.now()
        };
        switch (msg.event) {
        case "start":
        case "tool":
            pushEvent({ id: "live-" + sid, kind: "claudeLive", sessionId: sid, payload: payload, ttl: 0, staleAfter: 600000 });
            if (msg.event === "tool" && payload.tool)
                root.claudeFeed = [{ tool: payload.tool, detail: payload.detail, cwd: payload.cwd }].concat(root.claudeFeed).slice(0, 3);
            break;
        case "perm":
            pushEvent({ id: "perm-" + sid, kind: "claudePerm", sessionId: sid, payload: payload, ttl: 0, staleAfter: 600000 });
            root.claudeBurst("question");
            break;
        case "stop":
            root.queue = Q.endSession(root.queue, sid);
            refreshView();
            root.claudeBurst("confetti");
            if (msg.summary)
                Qt.callLater(() => root.flash("check_circle", msg.summary, { color: "#d97757", ms: 4500 }));
            break;
        case "end":
            root.queue = Q.endSession(root.queue, sid);
            refreshView();
            break;
        }
    }

    function handleOpencode(msg: var): void {
        const sid = msg.sessionId;
        if (!sid)
            return;
        const payload = {
            cwd: msg.cwd ?? "",
            tool: msg.tool ?? "",
            detail: msg.detail ?? "",
            pid: msg.pid ?? -1,
            elapsedMs: msg.elapsedMs ?? 0,
            startedAt: Date.now(),
            state: "working",
            attempt: msg.attempt ?? 0,
            retryAt: msg.retryAt ?? 0,
            summary: msg.summary ?? ""
        };
        switch (msg.event) {
        case "start":
        case "tool":
        case "retry":
        case "compact":
            payload.state = msg.event === "retry" || msg.event === "compact" ? msg.event : "working";
            pushEvent({ id: "oc-live-" + sid, kind: "opencodeLive", sessionId: sid, payload: payload, ttl: 0, staleAfter: 600000 });
            if (msg.event === "retry")
                root.opencodeBurst("pop");
            break;
        case "perm":
        case "ask":
            payload.state = msg.event === "ask" ? "question" : "permission";
            pushEvent({ id: "oc-perm-" + sid, kind: "opencodePerm", sessionId: sid, payload: payload, ttl: 0, staleAfter: 600000 });
            root.opencodeBurst("question");
            break;
        case "stop":
            root.queue = Q.endSession(root.queue, sid);
            refreshView();
            if (!msg.failed)
                root.opencodeBurst("confetti");
            if (msg.summary)
                Qt.callLater(() => root.flash(msg.failed ? "error" : "check_circle", msg.summary, { color: msg.failed ? String(Appearance.colors.colError) : "#2d7fa5", ms: 4500 }));
            break;
        case "end":
            root.queue = Q.endSession(root.queue, sid);
            refreshView();
            break;
        }
    }

    // DJ: the music island is out while music is recent and a player exists.
    readonly property bool djActive: IslandConfig.music && (root.playing || root.musicRecent) && MprisController.activePlayer !== null
    // True while the bar slots animate after DJ splits off / merges (slots report positions closely).
    property bool djAnimating: false
    onDjActiveChanged: {
        root.djAnimating = true;
        djAnimTimer.restart();
    }
    Timer {
        id: djAnimTimer
        interval: 750
        onTriggered: root.djAnimating = false
    }

    // Music counts as "recent" while playing and for 20 s after it stops; after that
    // the pill goes idle (glance) even if paused sources are still around.
    property real lastPlayingAt: 0
    property bool musicRecent: false
    Component.onCompleted: root.musicRecent = root.playing
    onPlayingChanged: {
        if (playing)
            root.musicRecent = true;
        else
            root.lastPlayingAt = Date.now();
        refreshView();
    }
    Timer {
        interval: 1000
        repeat: true
        running: !root.playing && root.musicRecent
        onTriggered: root.musicRecent = Date.now() - root.lastPlayingAt < 20000
    }

    // Real audio levels for the equaliser (3 bars, 0..1), from cava while music plays.
    property list<real> levels: [0, 0, 0]
    // cava is optional: without it the equaliser and the player's wave stay off (checked once).
    property bool cavaAvailable: false
    Process {
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: (code, status) => root.cavaAvailable = code === 0
    }
    Process {
        id: cavaProc
        running: root.playing && IslandConfig.equalizer && root.cavaAvailable
        command: ["cava", "-p", FileUtils.trimFileProtocol(Qt.resolvedUrl("cava/island.conf"))]
        onRunningChanged: if (!running) root.levels = [0, 0, 0]
        stdout: SplitParser {
            onRead: data => {
                const v = data.split(";").map(x => parseFloat(x)).filter(x => !isNaN(x));
                if (v.length >= 3)
                    root.levels = [v[0] / 100, v[1] / 100, v[2] / 100];
            }
        }
    }

    Connections {
        target: Notifications
        function onNotify(n) {
            // end-4's SongRec also notifies; the island's own song card covers it, so
            // drop that notification entirely (not even in history).
            if (IslandConfig.enabled && n.summary === Translation.tr("Music Recognized")) {
                const id = n.notificationId;
                Qt.callLater(() => Notifications.discardNotification(id));
                return;
            }
            // While the island is off, the stock popup owns notifications.
            if (Notifications.popupInhibited || !IslandConfig.enabled || root.quiet)
                return;
            const timeout = (n.notification && n.notification.expireTimeout > 0) ? n.notification.expireTimeout : (Config.options?.notifications?.timeout ?? 7000);
            root.pushEvent({
                id: "notif-" + n.notificationId,
                kind: "notif",
                payload: {
                    notificationId: n.notificationId,
                    appName: n.appName,
                    appIcon: n.appIcon,
                    summary: n.summary,
                    body: n.body,
                    image: n.image,
                    urgency: n.urgency,
                    actions: n.actions
                },
                ttl: timeout
            });
        }
        function onDiscard(id) {
            root.queue = Q.remove(root.queue, "notif-" + id);
            root.refreshView();
            if (Notifications.list.length === 0)
                Notifications.markAllRead();
        }
        // "Clear" (discardAllNotifications) emits only this, not one discard per id.
        function onDiscardAll() {
            root.queue = Q.removeKind(root.queue, "notif");
            root.refreshView();
            Notifications.markAllRead();
        }
    }

    // Expiry ticker, only runs while something is queued.
    Timer {
        interval: 250
        repeat: true
        running: root.queue.events.length > 0
        onTriggered: {
            const r = Q.expire(root.queue, Date.now());
            if (r.expired.length === 0)
                return;
            root.queue = r.state;
            for (const e of r.expired) {
                if (e.kind === "notif")
                    Notifications.timeoutNotification(e.payload.notificationId);
            }
            root.refreshView();
        }
    }

    // ---------------------------------------------------------------------------
    // Provider API: small, uniform ways for features to talk to the island.

    // Flash: brief content in the resting pill (layout switch, volume, output...).
    // opts: { color, progress (0..1, or -1 for none), ms }
    property var flashItem: null
    function flash(icon: string, text: string, opts: var): void {
        const o = opts ?? {};
        root.flashItem = { icon: icon, text: text, color: o.color ?? "", progress: o.progress ?? -1, at: Date.now() };
        flashTimer.interval = o.ms ?? 1600;
        flashTimer.restart();
    }
    Timer {
        id: flashTimer
        onTriggered: root.flashItem = null
    }

    // Activities: ongoing states (recording, timer, streaming, VM mode, offline...).
    // { icon, text, color, priority (>= 50 beats Claude and music), progress, command }
    property var activities: ({})
    property var topActivity: null
    function setActivity(id: string, a: var): void {
        const m = Object.assign({}, root.activities);
        m[id] = Object.assign({ id: id, priority: 10, progress: -1, color: "", command: [] }, a);
        root.activities = m;
    }
    function clearActivity(id: string): void {
        if (!(id in root.activities))
            return;
        const m = Object.assign({}, root.activities);
        delete m[id];
        root.activities = m;
    }
    onActivitiesChanged: {
        let top = null;
        for (const k in root.activities) {
            const a = root.activities[k];
            if (!top || a.priority > top.priority)
                top = a;
        }
        root.topActivity = top;
    }

    // Flashes requested from outside (scripts via IPC) win over automatic ones for a moment.
    property real lastExternalFlash: 0

    // Volume changed from the island: hide end-4's volume popup for a moment, since
    // the island already shows the level.
    property real suppressOsdUntil: 0
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged() {
            if (GlobalStates.osdVolumeOpen && Date.now() < root.suppressOsdUntil)
                GlobalStates.osdVolumeOpen = false;
        }
    }

    function suppressOsd(ms: int): void {
        root.suppressOsdUntil = Date.now() + ms;
    }

    // Idle glance: items the idle pill rotates through (weather, updates, load, disk...).
    // { icon, text, command, color, priority (higher first), graph (0..1 values → sparkline) }
    property var glances: ({})
    function setGlance(id: string, g: var): void {
        const m = Object.assign({}, root.glances);
        m[id] = Object.assign({ id: id, command: [], color: "", priority: 50, graph: [] }, g);
        root.glances = m;
    }
    function clearGlance(id: string): void {
        if (!(id in root.glances))
            return;
        const m = Object.assign({}, root.glances);
        delete m[id];
        root.glances = m;
    }

    // Long-press toggles → "What's playing?" (handled by the SongRecognizer provider).
    signal songRecognitionRequested()

    // Privacy dots on the pill's edge.
    property bool micDot: false
    property bool camDot: false

    // Quiet: no notification drops (games, streaming); they still go to history.
    property bool quiet: false

    // Info cards drop out like notifications. { icon, title, body, accent, ttl }
    function pushCard(id: string, c: var): void {
        pushEvent({ id: "info-" + id, kind: "info", payload: c, ttl: c.ttl ?? 6000 });
    }

    // Album accent (set by the AlbumAccent provider) for equaliser/progress.
    property color accent: "transparent"

    // Current synced lyric line (set by the Lyrics provider), shown instead of the title.
    property string lyricLine: ""

    // Claude extras: recent tools (hover feed) and number of live sessions.
    property var claudeFeed: []
    readonly property int claudeSessions: root.queue.events.filter(e => e.kind === "claudeLive" || e.kind === "claudePerm").length
    function focusClaude(): void {
        const e = root.queue.events.find(x => x.kind === "claudePerm") ?? root.queue.events.find(x => x.kind === "claudeLive");
        if (e)
            root.focusPid(e.payload.pid);
    }

    IpcHandler {
        target: "island"

        function ping(): string {
            return "pong";
        }

        // Long terminal command finished (shell hook): island command <cmd> <exit status> <duration ms>
        function command(cmd: string, status: int, ms: int): void {
            const s = Math.round(ms / 1000);
            const dur = s >= 60 ? Math.floor(s / 60) + "m " + (s % 60) + "s" : s + "s";
            root.pushCard("cmd-" + Date.now(), {
                icon: status === 0 ? "check_circle" : "error",
                title: cmd.length > 40 ? cmd.slice(0, 39) + "…" : cmd,
                body: (status === 0 ? Translation.tr("Finished") : Translation.tr("Failed (exit %1)").arg(status)) + " · " + dur,
                accent: status === 0 ? "#3fb950" : String(Appearance.colors.colError),
                ttl: 7000
            });
        }

        // For scripts: qs -c ii ipc call island flash <material-icon> <text>
        function flash(icon: string, text: string): void {
            root.lastExternalFlash = Date.now();
            root.flash(icon, text, { ms: 2000 });
        }

        function claude(json: string): void {
            if (!IslandConfig.codingAgents)
                return;
            try {
                root.handleClaude(JSON.parse(json));
            } catch (e) {
                console.warn("[island] bad claude payload: " + e);
            }
        }

        function opencode(json: string): void {
            if (!IslandConfig.codingAgents)
                return;
            try {
                root.handleOpencode(JSON.parse(json));
            } catch (e) {
                console.warn("[island] bad opencode payload: " + e);
            }
        }

        // Opens DJ's player on the focused screen, like a click on DJ (closes the normal way).
        function openPlayer(): void {
            root.cardRequested("player");
        }

        function openOverview(): void {
            root.cardRequested("overview");
        }
        // Long-press card; closeOverview closes it.
        function openToggles(): void {
            root.cardRequested("toggles");
        }
        function closeOverview(): void {
            root.cardCloseRequested();
        }
        function closePlayer(): void {
            root.cardCloseRequested();
        }

        function state(): string {
            return JSON.stringify({ main: root.main, live: root.live, opencodeLive: root.opencodeLive, opencodeWaiting: root.opencodeWaiting, opencodeState: root.opencodeState, bubble: root.bubble, extra: root.extra, playing: root.playing, activities: root.activities, flash: root.flashItem, micDot: root.micDot, camDot: root.camDot, quiet: root.quiet, lyricLine: root.lyricLine, accent: String(root.accent), glances: root.glances, slots: root.slots, djActive: root.djActive, musicRecent: root.musicRecent, config: { enabled: IslandConfig.enabled, music: IslandConfig.music, equalizer: IslandConfig.equalizer, lyrics: IslandConfig.lyrics, clipboard: IslandConfig.clipboard, codingAgents: IslandConfig.codingAgents, systemMonitor: IslandConfig.systemMonitor }, cava: cavaProc.running });
        }

        function test(kind: string): void {
            const sid = "test";
            switch (kind) {
            case "music":
                root.pushEvent({ id: "music", kind: "music", payload: { title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", artUrl: "" }, ttl: 4000 });
                break;
            case "notif":
                root.pushEvent({ id: "notif-test-" + Date.now(), kind: "notif", payload: { notificationId: -1, appName: "Discord", appIcon: "", summary: "Alex", body: "you up for a match tonight?", image: "", urgency: "normal", actions: [{ identifier: "reply", text: "Reply" }] }, ttl: 7000 });
                break;
            case "claudePerm":
                root.handleClaude({ event: "perm", sessionId: sid, cwd: "~/.config/hypr", tool: "Bash", detail: "hyprctl reload" });
                break;
            case "claudeDone":
                root.handleClaude({ event: "stop", sessionId: sid, cwd: "~/.config/hypr", elapsedMs: 192000 });
                break;
            case "claudeLive":
                root.handleClaude({ event: "tool", sessionId: sid, cwd: "~/.config/hypr", tool: "Edit", detail: "Island.qml" });
                break;
            case "opencodePerm":
                root.handleOpencode({ event: "perm", sessionId: "test", cwd: "~/project", tool: "Bash", detail: "make build" });
                break;
            case "opencodeDone":
                root.handleOpencode({ event: "stop", sessionId: "test", cwd: "~/project", elapsedMs: 120000 });
                break;
            case "opencodeAsk":
                root.handleOpencode({ event: "ask", sessionId: "test", detail: "Which database should I use?" });
                break;
            case "opencodeRetry":
                root.handleOpencode({ event: "retry", sessionId: "test", attempt: 2, retryAt: Date.now() + 15000, summary: "Rate limited" });
                break;
            case "opencodeCompact":
                root.handleOpencode({ event: "compact", sessionId: "test" });
                break;
            case "opencodeLive":
                root.handleOpencode({ event: "tool", sessionId: "test", cwd: "~/project", tool: "Bash", detail: "git status" });
                break;
            case "flash":
                root.flash("keyboard", "AM", {});
                break;
            case "activity":
                root.setActivity("test", { icon: "radio_button_checked", text: "REC 0:42", color: String(Appearance.colors.colError), priority: 80 });
                break;
            case "noactivity":
                root.clearActivity("test");
                break;
            case "card":
                root.pushCard("test", { icon: "rainy", title: "Rain in Berlin", body: "Light rain now · 12°C", accent: "" });
                break;
            case "imagecard":
                root.pushCard("test", { icon: "image", title: "Image copied", body: "Test thumbnail", image: "/usr/share/pixmaps/archlinux-logo.png" });
                break;
            case "idle":
                root.lastPlayingAt = 0;
                root.musicRecent = false;
                break;
            case "clear":
                root.queue = Q.newState();
                root.refreshView();
                break;
            }
        }
    }
}
