pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Local Claude Code for the Intelligence tab of the left sidebar.
 * Talks to cc-host (scripts/claudeCode/cc-host.mjs), a small daemon that keeps
 * `claude -p` stream-json sessions alive and turns their events into chat items.
 * The host outlives shell reloads, so a running turn is never interrupted.
 */
Singleton {
    id: root

    readonly property int hostVersion: 1
    readonly property string home: FileUtils.trimFileProtocol(Directories.home)
    readonly property string hostPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/claudeCode/cc-host.mjs`
    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-claude-code.sock`
    readonly property string defaultKey: "default"
    readonly property string defaultName: Config.options.ai.claudeCode.defaultSessionName
    readonly property string defaultDir: Config.options.ai.claudeCode.defaultSessionDir || root.home
    readonly property string newSessionDir: Config.options.ai.claudeCode.newSessionDir || root.home

    readonly property bool enabled: Config.options.ai.claudeCode.enable
    readonly property bool active: root.enabled && Persistent.states.ai.claudeCode.active
    readonly property var state: Persistent.states.ai.claudeCode

    // Host
    readonly property bool connected: socket.connected
    property var sessions: ({}) // key -> meta from the host
    property var labels: ({}) // key -> display name
    property string activeKey: ""
    readonly property var activeMeta: sessions[activeKey] ?? null
    // Labels live in memory; after a reload fall back to the session's folder name
    readonly property string activeLabel: labels[activeKey] ?? (activeMeta?.name || (activeMeta?.cwd ?? "").split("/").pop())
    readonly property bool busy: ["busy", "waiting"].includes(activeMeta?.status ?? "")

    // Items of the session on screen
    property list<string> itemIds: []
    property var itemObjects: ({}) // id -> holder { d: item }
    property var tasks: []
    property Component holder: Component {
        QtObject {
            property var d
        }
    }

    // Session picker
    property var recentSessions: []
    property bool sessionsLoading: false
    property bool sessionMenuOpen: false
    property string menuNotice: ""
    property string pendingShow: ""

    signal messageSent
    signal itemsUpdated

    function setActive(value) {
        root.state.active = value;
    }
    function toggleActive() {
        root.setActive(!root.active);
    }

    // ---------- connection ----------

    readonly property bool shouldRun: Persistent.ready && root.active
    onShouldRunChanged: if (shouldRun)
        ensureStarted()

    property bool wanted: false
    property real lastLaunch: 0
    function ensureStarted() {
        root.wanted = true;
        if (!socket.connected)
            socket.connected = true;
    }

    Socket {
        id: socket
        path: root.socketPath
        parser: SplitParser {
            onRead: data => root.handleEvent(data)
        }
        onConnectedChanged: {
            if (connected)
                root.send({ op: "hello" });
            else if (root.wanted)
                reconnectTimer.restart();
        }
        onError: error => {
            // No host yet: start one, detached so it outlives shell reloads
            if (Date.now() - root.lastLaunch > 5000) {
                root.lastLaunch = Date.now();
                Quickshell.execDetached(["node", root.hostPath]);
            }
            reconnectTimer.restart();
        }
    }
    Timer {
        id: reconnectTimer
        interval: 400
        onTriggered: if (root.wanted && !socket.connected)
            socket.connected = true
    }

    function send(obj) {
        if (!socket.connected)
            return;
        socket.write(JSON.stringify(obj) + "\n");
        socket.flush();
    }

    // ---------- sessions ----------

    function uuid() {
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, c => {
            const r = Math.random() * 16 | 0;
            return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    function setLabel(key, label) {
        const l = Object.assign({}, root.labels);
        l[key] = label;
        root.labels = l;
    }

    function open(key, label, sessionId, cwd, extra = {}) {
        root.setLabel(key, label);
        root.send(Object.assign({
            op: "open",
            key: key,
            sessionId: sessionId,
            cwd: cwd,
            mode: root.state.permissionMode
        }, extra));
        root.activate(key);
    }

    function activate(key) {
        root.sessionMenuOpen = false;
        if (root.activeKey !== key)
            root.clearItems();
        root.activeKey = key;
        if (key !== "fixture")
            root.state.lastKey = key;
        root.send({ op: "subscribe", key: key });
    }

    function openDefault() {
        if (!root.state.sessionId)
            root.state.sessionId = root.uuid();
        root.open(root.defaultKey, root.defaultName, root.state.sessionId, root.defaultDir, { name: root.defaultName });
    }

    function openSession(s) {
        // s: entry of recentSessions
        if (s.id === root.state.sessionId)
            return root.openDefault();
        for (const key in root.sessions) {
            if (root.sessions[key].sessionId === s.id)
                return root.activate(key);
        }
        // Running in a terminal or in the background: work on a copy
        if (s.live)
            return root.open(s.id + ":fork", (s.title || s.id.slice(0, 8)) + " (fork)", s.id, s.cwd, { fork: true });
        root.open(s.id, s.title || s.id.slice(0, 8), s.id, s.cwd);
    }

    function newSession(cwd) {
        const id = root.uuid();
        root.open(id, Translation.tr("New session"), id, cwd || root.newSessionDir, { fresh: true });
    }

    function closeSession(key) {
        root.send({ op: "close", key: key });
    }

    function deleteSession(id) {
        // The host refuses running sessions and the default one
        root.send({ op: "deleteSession", sessionId: id, protect: root.state.sessionId });
    }

    function clearConversation() {
        // /clear: same place, new conversation
        const id = root.uuid();
        if (root.activeKey === root.defaultKey)
            root.state.sessionId = id;
        root.clearItems();
        root.send({ op: "reset", key: root.activeKey, sessionId: id });
    }

    function refreshSessions() {
        root.sessionsLoading = true;
        root.send({ op: "listSessions" });
    }
    onSessionMenuOpenChanged: {
        root.menuNotice = "";
        if (sessionMenuOpen)
            refreshSessions();
    }

    // ---------- conversation ----------

    function sendMessage(text, images = []) {
        if (!root.activeKey)
            return;
        root.send({ op: "send", key: root.activeKey, text: text, images: images });
        root.messageSent();
    }
    function interrupt() {
        root.send({ op: "interrupt", key: root.activeKey });
    }
    function answerPermission(requestId, decision) {
        root.send({ op: "permission", key: root.activeKey, requestId: requestId, decision: decision });
    }
    function setModel(model) {
        root.send({ op: "setModel", key: root.activeKey, model: model });
    }
    function setPermissionMode(mode) {
        root.state.permissionMode = mode;
        root.send({ op: "setMode", key: root.activeKey, mode: mode });
    }

    function clearItems() {
        for (const id in root.itemObjects)
            root.itemObjects[id].destroy();
        root.itemObjects = {};
        root.itemIds = [];
        root.tasks = [];
    }

    function upsertItems(items) {
        const added = [];
        for (const it of items) {
            const o = root.itemObjects[it.id];
            if (o) {
                o.d = it;
                continue;
            }
            root.itemObjects[it.id] = root.holder.createObject(root, { d: it });
            added.push(it.id);
        }
        if (added.length > 0)
            root.itemIds = root.itemIds.concat(added);
        root.itemsUpdated();
    }

    function setSession(meta) {
        const prevStatus = root.sessions[meta.key]?.status;
        const s = Object.assign({}, root.sessions);
        s[meta.key] = meta;
        root.sessions = s;
        if (meta.key === root.defaultKey && meta.sessionId && meta.sessionId !== root.state.sessionId)
            root.state.sessionId = meta.sessionId;
        if (prevStatus === "busy" && meta.status === "idle")
            root.notifyReply(meta);
    }

    // A reply finished while the sidebar was closed
    function notifyReply(meta) {
        if (GlobalStates.sidebarLeftOpen || meta.key === "fixture")
            return;
        const title = root.labels[meta.key] ?? (meta.name || (meta.cwd ?? "").split("/").pop() || "Claude Code");
        let body = "";
        if (meta.key === root.activeKey) {
            for (let i = root.itemIds.length - 1; i >= 0 && !body; i--) {
                const it = root.itemObjects[root.itemIds[i]]?.d;
                if (it?.kind === "text")
                    body = it.text.trim();
            }
        }
        if (body.length > 200)
            body = body.slice(0, 200) + "…";
        Quickshell.execDetached(["notify-send", "-a", "Claude Code", title, body || Translation.tr("Reply ready")]);
    }

    function handleEvent(line) {
        let e;
        try {
            e = JSON.parse(line);
        } catch (err) {
            return;
        }
        switch (e.ev) {
        case "hello": {
            if (e.version !== root.hostVersion) {
                // An older host from before an update: replace it
                root.send({ op: "shutdown" });
                return;
            }
            const s = {};
            for (const m of e.sessions)
                s[m.key] = m;
            root.sessions = s;
            // Back to where we were, or the default session
            const key = root.activeKey || root.state.lastKey;
            if (key && key !== root.defaultKey && s[key])
                root.activate(key);
            else
                root.openDefault();
            break;
        }
        case "snapshot":
            root.setSession(e.meta);
            if (e.key !== root.activeKey)
                break;
            root.clearItems();
            root.upsertItems(e.items);
            root.tasks = e.tasks;
            break;
        case "items":
            if (e.key === root.activeKey)
                root.upsertItems(e.items);
            break;
        case "meta":
            root.setSession(e.meta);
            break;
        case "tasks":
            if (e.key === root.activeKey)
                root.tasks = e.tasks;
            break;
        case "closed": {
            const s = Object.assign({}, root.sessions);
            delete s[e.key];
            root.sessions = s;
            if (e.key !== root.activeKey)
                break;
            root.clearItems();
            root.activeKey = "";
            root.openDefault();
            break;
        }
        case "sessionList": {
            root.recentSessions = e.sessions;
            root.sessionsLoading = false;
            if (!root.pendingShow)
                break;
            const q = root.pendingShow;
            root.pendingShow = "";
            const s = e.sessions.find(s => s.id.startsWith(q)) ?? e.sessions.find(s => s.title.toLowerCase().includes(q.toLowerCase()));
            if (s)
                root.openSession(s);
            break;
        }
        case "deleted":
            if (e.ok) {
                root.recentSessions = root.recentSessions.filter(s => s.id !== e.sessionId);
                if (root.state.lastKey === e.sessionId)
                    root.state.lastKey = "";
                root.menuNotice = "";
            } else {
                root.menuNotice = e.error ?? Translation.tr("Could not delete the session");
            }
            root.refreshSessions();
            break;
        case "error":
            console.warn("[ClaudeCode] host:", e.message);
            break;
        }
    }

    // ---------- ipc ----------

    IpcHandler {
        target: "claudeCode"

        function setActive(active: bool): void {
            root.setActive(active);
        }
        function sessionMenu(open: bool): void {
            root.sessionMenuOpen = open;
        }
        function message(text: string): void {
            root.sendMessage(text);
        }
        function defaultSession(): void {
            root.openDefault();
        }
        // Show a session: full id, id prefix or part of its title
        function showSession(session: string): void {
            root.ensureStarted();
            root.pendingShow = session;
            root.refreshSessions();
        }
        function newSession(cwd: string): void {
            root.newSession(cwd);
        }
        function close(key: string): void {
            root.closeSession(key);
        }
        // Show a recorded `claude -p --output-format stream-json` transcript (screenshots, debugging)
        function replay(file: string): void {
            root.ensureStarted();
            root.setLabel("fixture", root.defaultName);
            root.send({ op: "replay", key: "fixture", file: file });
            root.activate("fixture");
        }
        function status(): string {
            return JSON.stringify({
                active: root.active,
                connected: root.connected,
                session: root.activeKey,
                items: root.itemIds.length,
                sessions: root.sessions
            });
        }
    }
}
