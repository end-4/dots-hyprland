#!/usr/bin/env node
// cc-host: keeps Claude Code sessions for the sidebar (Intelligence > Claude Code).
//
// Each session is a long-lived `claude -p` speaking stream-json on stdio (the
// protocol the Agent SDK uses). Events are normalized into flat chat items and
// served over a unix socket as JSON lines, so the shell can reload or restart
// without interrupting a running turn.
//
// client -> host
//   {op:"hello"}                                   -> {ev:"hello", sessions}
//   {op:"open", key, sessionId, cwd, name?, fresh?, model?, mode?, fork?} start or reuse a session
//   {op:"subscribe", key}                          -> {ev:"snapshot", key, meta, items, tasks}
//   {op:"send", key, text, images?}                user message (images: file paths)
//   {op:"interrupt", key}
//   {op:"permission", key, requestId, decision}    decision: allow | always | deny
//   {op:"setModel", key, model}  {op:"setMode", key, mode}
//   {op:"reset", key, sessionId}                   start over with a new conversation id
//   {op:"close", key}
//   {op:"record", key, file}                       tee raw claude stdout (fixtures)
//   {op:"replay", key, file}                       session fed from a recorded stdout
//   {op:"listSessions"}                            -> {ev:"sessionList", sessions} (all projects)
//   {op:"deleteSession", sessionId, protect?}      -> {ev:"deleted", sessionId, ok, error?}
//   {op:"shutdown"}
// host -> client
//   {ev:"hello", version, sessions}
//   {ev:"meta", key, meta}  {ev:"items", key, items}  {ev:"tasks", key, tasks}
//   {ev:"closed", key}  {ev:"error", message}

import net from "node:net";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import readline from "node:readline";
import { spawn, execFile } from "node:child_process";

// Bump when the protocol changes: the shell replaces a running host with another version
const VERSION = 1;
const RUNTIME = process.env.XDG_RUNTIME_DIR || os.tmpdir();
const SOCK = process.env.II_CC_SOCK || path.join(RUNTIME, "quickshell-claude-code.sock");
const STATE_DIR = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"), "quickshell/user");
const LOG = path.join(STATE_DIR, "claude-code-host.log");
const CLAUDE_DIR = path.join(os.homedir(), ".claude");
const PROJECTS = path.join(CLAUDE_DIR, "projects");
const FLUSH_MS = 40;
const MAX_OUTPUT = 4000;
const MAX_DIFF_LINES = 160;
const HISTORY_ITEMS = 400;

fs.mkdirSync(STATE_DIR, { recursive: true });
function log(...a) {
    fs.appendFileSync(LOG, `[${new Date().toISOString()}] ${a.join(" ")}\n`);
}

function resolveClaudeCmd(cmd) {
    if (cmd.includes("/")) return cmd;
    const dirs = (process.env.PATH || "").split(":").concat([path.join(os.homedir(), ".local/bin"), "/usr/bin"]);
    for (const d of dirs) {
        const p = path.join(d, cmd);
        try {
            fs.accessSync(p, fs.constants.X_OK);
            return p;
        } catch {}
    }
    return cmd;
}

const CLAUDE = resolveClaudeCmd(process.env.II_CLAUDE_CMD || "claude");

// ---------- clients ----------

const clients = new Set();
function broadcast(obj) {
    const line = JSON.stringify(obj) + "\n";
    for (const c of clients) c.write(line);
}

// ---------- helpers ----------

function truncate(s, n = MAX_OUTPUT) {
    s = String(s ?? "");
    return s.length > n ? s.slice(0, n) + `\n… (${s.length - n} more characters)` : s;
}

function resultText(content) {
    if (typeof content === "string") return content;
    if (!Array.isArray(content)) return "";
    return content.map(b => (b.type === "text" ? b.text : b.type === "image" ? "[image]" : "")).join("\n");
}

function shortPath(p) {
    const h = os.homedir();
    return p && p.startsWith(h) ? "~" + p.slice(h.length) : p || "";
}

function toolTitle(name, input = {}) {
    switch (name) {
        case "Bash":
            return input.description || (input.command || "").split("\n")[0];
        case "Read":
        case "Write":
        case "Edit":
        case "MultiEdit":
        case "NotebookEdit":
            return shortPath(input.file_path || input.notebook_path);
        case "Grep":
            return `${input.pattern ?? ""}${input.path ? "  in " + shortPath(input.path) : ""}`;
        case "Glob":
            return input.pattern ?? "";
        case "WebFetch":
            return input.url ?? "";
        case "WebSearch":
            return input.query ?? "";
        case "Task":
        case "Agent":
            return input.description || input.subagent_type || "";
        case "Skill":
            return input.skill || input.command || "";
        case "SendMessage":
            return `→ ${input.to ?? ""}`;
        case "ToolSearch":
            return input.query ?? "";
        case "TaskCreate":
            return input.subject ?? "";
        case "TaskUpdate":
            return `#${input.taskId ?? "?"} → ${input.status ?? ""}`;
    }
    const first = Object.values(input).find(v => typeof v === "string");
    return first ? first.split("\n")[0] : "";
}

function diffFromPatch(filePath, patch) {
    const hunks = [];
    let budget = MAX_DIFF_LINES;
    for (const h of patch || []) {
        if (budget <= 0) break;
        const lines = h.lines.slice(0, budget);
        budget -= lines.length;
        hunks.push({ header: `@@ -${h.oldStart},${h.oldLines} +${h.newStart},${h.newLines} @@`, lines });
    }
    return { path: shortPath(filePath), hunks };
}

function diffFromInput(name, input) {
    if (name === "Edit" && input.old_string != null)
        return {
            path: shortPath(input.file_path),
            hunks: [{ header: "", lines: [...input.old_string.split("\n").map(l => "-" + l), ...input.new_string.split("\n").map(l => "+" + l)].slice(0, MAX_DIFF_LINES) }],
        };
    if (name === "MultiEdit" && Array.isArray(input.edits))
        return {
            path: shortPath(input.file_path),
            hunks: input.edits.map(e => ({ header: "", lines: [...e.old_string.split("\n").map(l => "-" + l), ...e.new_string.split("\n").map(l => "+" + l)] })),
        };
    if (name === "Write" && typeof input.content === "string")
        return { path: shortPath(input.file_path), created: true, hunks: [{ header: "", lines: input.content.split("\n").slice(0, MAX_DIFF_LINES).map(l => "+" + l) }] };
    return null;
}

const CMD_RE = /<command-name>(.*?)<\/command-name>[\s\S]*?(?:<command-args>([\s\S]*?)<\/command-args>)?/;
const STDOUT_RE = /<local-command-stdout>([\s\S]*?)<\/local-command-stdout>/;
const PEER_RE = /<cross-session-message[^>]*from-name="([^"]*)"[^>]*>([\s\S]*?)<\/cross-session-message>/;

function findTranscript(sessionId) {
    if (!sessionId) return null;
    try {
        for (const dir of fs.readdirSync(PROJECTS)) {
            const p = path.join(PROJECTS, dir, `${sessionId}.jsonl`);
            if (fs.existsSync(p)) return p;
        }
    } catch {}
    return null;
}

// ---------- sessions ----------

const sessions = new Map();

class Session {
    constructor({ key, sessionId, cwd, name, model, fork, mode }) {
        this.key = key;
        this.meta = {
            key,
            sessionId,
            cwd,
            name: name || "",
            requestedModel: model || "",
            fork: !!fork,
            requestedMode: mode || "",
            model: "",
            permissionMode: "",
            commands: [],
            models: [],
            status: "idle", // idle | starting | busy | waiting | exited
            statusText: "",
            alive: false,
        };
        this.items = [];
        this.byId = new Map();
        this.toolItems = new Map(); // tool_use id -> item
        this.tasks = new Map();
        this.seq = 0;
        this.dirty = new Set();
        this.timer = null;
        this.proc = null;
        this.pending = new Map(); // our control requests
        this.permissions = new Map(); // request_id -> {request, itemId}
        this.cur = null; // streaming message state
        this.record = null;
        this.stderr = "";
        this.echoes = 0; // messages shown on send whose replayed copy hasn't arrived yet
    }

    // ----- items -----
    add(item, parent = null) {
        item.id = `${this.key.slice(0, 8)}-${++this.seq}`;
        if (parent) item.depth = 1;
        this.items.push(item);
        this.byId.set(item.id, item);
        this.touch(item);
        return item;
    }
    touch(item) {
        this.dirty.add(item.id);
        if (!this.timer) this.timer = setTimeout(() => this.flush(), FLUSH_MS);
    }
    flush() {
        this.timer = null;
        if (this.dirty.size === 0 || this.gone) return;
        const items = [...this.dirty].map(id => this.byId.get(id)).filter(Boolean);
        this.dirty.clear();
        broadcast({ ev: "items", key: this.key, items });
    }
    setMeta(patch) {
        Object.assign(this.meta, patch);
        // A closed or replaced session's process still exits afterwards: keep it quiet
        if (this.gone) return;
        broadcast({ ev: "meta", key: this.key, meta: this.meta });
    }
    emitTasks() {
        if (this.gone) return;
        broadcast({ ev: "tasks", key: this.key, tasks: [...this.tasks.values()] });
    }
    snapshot() {
        return { ev: "snapshot", key: this.key, meta: this.meta, items: this.items, tasks: [...this.tasks.values()] };
    }

    // ----- process -----
    start(fresh) {
        if (this.proc) return;
        const args = ["-p", "--input-format", "stream-json", "--output-format", "stream-json",
            "--include-partial-messages", "--verbose", "--replay-user-messages",
            "--permission-prompt-tool", "stdio"];
        const transcript = findTranscript(this.meta.sessionId);
        if (transcript && !fresh) args.push("--resume", this.meta.sessionId, ...(this.meta.fork ? ["--fork-session"] : []));
        else args.push("--session-id", this.meta.sessionId);
        if (this.meta.name) args.push("-n", this.meta.name);
        if (this.meta.requestedModel) args.push("--model", this.meta.requestedModel);
        if (this.meta.requestedMode) args.push("--permission-mode", this.meta.requestedMode);
        // Print mode leaves out the task tools unless asked; the sidebar shows them as a checklist
        const env = { ...process.env, CLAUDE_CODE_ENABLE_TODO_TOOLS: "1" };
        delete env.CLAUDECODE;
        log("spawn", this.key, this.meta.cwd, args.join(" "));
        let proc;
        try {
            proc = spawn(CLAUDE, args, { cwd: this.meta.cwd || os.homedir(), env, stdio: ["pipe", "pipe", "pipe"] });
        } catch (e) {
            this.add({ kind: "system", level: "error", text: `Failed to start claude: ${e.message}` });
            return;
        }
        this.proc = proc;
        this.stderr = "";
        this.echoes = 0;
        this.setMeta({ alive: true, status: "starting" });
        readline.createInterface({ input: proc.stdout }).on("line", line => {
            if (this.record) fs.appendFileSync(this.record, line + "\n");
            let e;
            try {
                e = JSON.parse(line);
            } catch {
                return;
            }
            try {
                this.handle(e);
            } catch (err) {
                log("handle error", this.key, err.stack);
            }
        });
        proc.stderr.on("data", d => {
            this.stderr = (this.stderr + d).slice(-2000);
        });
        proc.on("exit", code => {
            log("exit", this.key, code, this.stderr.trim().slice(-300));
            this.proc = null;
            for (const [, p] of this.permissions) this.resolvePermissionItem(p.itemId, "cancelled");
            this.permissions.clear();
            if (code && this.meta.status !== "closing")
                this.add({ kind: "system", level: "error", text: `Claude Code exited (${code})${this.stderr.trim() ? ": " + this.stderr.trim().split("\n").slice(-3).join(" ") : ""}` });
            this.setMeta({ alive: false, status: "exited" });
        });
        proc.stdin.on("error", () => {});
        this.control({ subtype: "initialize" }).then(r => {
            if (!r) return;
            this.setMeta({
                commands: (r.commands || []).map(c => ({ name: c.name, description: c.description || "", argumentHint: c.argumentHint || "" })),
                models: (r.models || []).map(m => ({ value: m.value, name: m.displayName || m.value, description: m.description || "" })),
                permissionMode: this.meta.permissionMode || r.current_permission_mode || "",
                status: this.meta.status === "starting" ? "idle" : this.meta.status,
            });
        });
    }
    write(obj) {
        if (this.proc) this.proc.stdin.write(JSON.stringify(obj) + "\n");
    }
    control(request) {
        const id = crypto.randomUUID();
        this.write({ type: "control_request", request_id: id, request });
        return new Promise(resolve => {
            this.pending.set(id, resolve);
            setTimeout(() => this.pending.delete(id) && resolve(null), 15000);
        });
    }
    send(text, images = []) {
        if (!this.proc) this.start(false);
        const content = [];
        for (const file of images || []) {
            try {
                const data = fs.readFileSync(file).toString("base64");
                const ext = path.extname(file).slice(1).toLowerCase();
                const media = ext === "jpg" ? "image/jpeg" : `image/${ext || "png"}`;
                content.push({ type: "image", source: { type: "base64", media_type: media, data } });
            } catch (e) {
                this.add({ kind: "system", level: "error", text: `Could not attach ${file}: ${e.message}` });
            }
        }
        content.push({ type: "text", text });
        this.write({ type: "user", message: { role: "user", content }, parent_tool_use_id: null, session_id: this.meta.sessionId });
        // Show it right away; Claude replays it only once the turn starts
        this.add({ kind: "user", text, images: images.length });
        this.echoes++;
        this.cur = null;
        this.setMeta({ status: "busy", statusText: "" });
    }
    answerPermission(requestId, decision) {
        const p = this.permissions.get(requestId);
        if (!p) return;
        this.permissions.delete(requestId);
        const r = p.request;
        const response = decision === "deny"
            ? { behavior: "deny", message: "The user declined this action in the sidebar." }
            : { behavior: "allow", updatedInput: r.input, ...(decision === "always" && r.permission_suggestions ? { updatedPermissions: r.permission_suggestions } : {}) };
        this.write({ type: "control_response", response: { subtype: "success", request_id: requestId, response } });
        this.resolvePermissionItem(p.itemId, decision === "deny" ? "denied" : decision === "always" ? "always" : "allowed");
        if (this.permissions.size === 0) this.setMeta({ status: "busy" });
    }
    resolvePermissionItem(itemId, state) {
        const it = this.byId.get(itemId);
        if (!it) return;
        if (it.kind === "tool") it.permission.state = state;
        else it.state = state;
        this.touch(it);
    }
    kill() {
        this.gone = true;
        if (this.proc) {
            this.meta.status = "closing";
            this.proc.kill("SIGTERM");
        }
    }

    // ----- event normalization -----
    handle(e) {
        const parent = e.parent_tool_use_id || null;
        switch (e.type) {
            case "system":
                return this.handleSystem(e);
            case "stream_event":
                return this.handleStream(e.event, parent);
            case "assistant":
                return this.handleAssistant(e.message, parent);
            case "user":
                return this.handleUser(e, parent);
            case "result":
                return this.handleResult(e);
            case "control_request":
                return this.handleControlRequest(e);
            case "control_response": {
                const r = e.response || {};
                const resolve = this.pending.get(r.request_id);
                if (resolve) {
                    this.pending.delete(r.request_id);
                    resolve(r.response || null);
                }
                return;
            }
        }
    }

    handleSystem(e) {
        switch (e.subtype) {
            case "init":
                this.setMeta({
                    model: e.model || "",
                    permissionMode: e.permissionMode || "",
                    sessionId: e.session_id || this.meta.sessionId,
                    status: this.meta.status === "starting" ? "idle" : this.meta.status,
                    cwd: e.cwd || this.meta.cwd,
                });
                if (this.meta.commands.length === 0 && Array.isArray(e.slash_commands))
                    this.setMeta({ commands: e.slash_commands.map(n => ({ name: n, description: "", argumentHint: "" })) });
                return;
            case "status":
                return this.setMeta({ statusText: e.status || "" });
            case "thinking_tokens": {
                const t = this.cur?.thinking ?? this.currentThinking(true);
                t.tokens = e.estimated_tokens ?? t.tokens;
                this.touch(t);
                return;
            }
            case "permission_denied": {
                const tool = this.toolItems.get(e.tool_use_id);
                if (tool) {
                    tool.status = "denied";
                    tool.output = e.message || "";
                    this.touch(tool);
                } else this.add({ kind: "system", level: "warning", text: e.message || "Permission denied" });
                return;
            }
            case "compact_boundary":
                return void this.add({ kind: "system", level: "info", text: "Conversation compacted" });
        }
    }

    currentThinking(create) {
        const cur = this.cur;
        if (cur && cur.thinking && !cur.thinking.done) return cur.thinking;
        if (!create) return null;
        const t = this.add({ kind: "thinking", text: "", tokens: 0, done: false });
        if (cur) cur.thinking = t;
        else this.cur = { msgId: null, blocks: new Map(), thinking: t, counts: {} };
        return t;
    }

    handleStream(ev, parent) {
        if (!ev) return;
        switch (ev.type) {
            case "message_start":
                // Keep a thinking item opened by thinking_tokens before the message started
                this.cur = { msgId: ev.message?.id, blocks: new Map(), thinking: this.cur?.msgId == null ? this.cur?.thinking ?? null : null, counts: {}, parent };
                return;
            case "content_block_start": {
                const cb = ev.content_block || {};
                if (!this.cur) this.cur = { msgId: null, blocks: new Map(), thinking: null, counts: {}, parent };
                let item;
                if (cb.type === "text") item = this.add({ kind: "text", text: "", done: false }, parent);
                else if (cb.type === "thinking" || cb.type === "redacted_thinking") item = this.currentThinking(true);
                else if (cb.type === "tool_use" || cb.type === "server_tool_use") {
                    item = this.add({ kind: "tool", toolId: cb.id, name: cb.name, title: "", input: {}, inputJson: "", status: "running", output: "", diff: null }, parent);
                    this.toolItems.set(cb.id, item);
                }
                if (item) this.cur.blocks.set(ev.index, item);
                return;
            }
            case "content_block_delta": {
                const item = this.cur?.blocks.get(ev.index);
                const d = ev.delta || {};
                if (!item) return;
                if (d.type === "text_delta") item.text += d.text;
                else if (d.type === "thinking_delta") item.text += d.thinking;
                else if (d.type === "input_json_delta") item.inputJson += d.partial_json;
                else return;
                this.touch(item);
                return;
            }
            case "content_block_stop": {
                const item = this.cur?.blocks.get(ev.index);
                if (!item) return;
                if (item.kind === "text" || item.kind === "thinking") item.done = true;
                if (item.kind === "tool" && item.inputJson) {
                    try {
                        this.setToolInput(item, JSON.parse(item.inputJson));
                    } catch {}
                }
                this.touch(item);
                return;
            }
        }
    }

    setToolInput(item, input) {
        item.input = input;
        item.title = toolTitle(item.name, input);
        if (!item.diff) item.diff = diffFromInput(item.name, input);
        if (item.name === "TaskUpdate" && input.taskId != null) {
            const t = this.tasks.get(String(input.taskId)) || { id: String(input.taskId), subject: input.subject || `#${input.taskId}`, status: "pending" };
            if (input.status) t.status = input.status;
            if (input.subject) t.subject = input.subject;
            if (input.activeForm) t.activeForm = input.activeForm;
            if (t.status === "deleted") this.tasks.delete(t.id);
            else this.tasks.set(t.id, t);
            this.emitTasks();
        }
        if (item.name === "TodoWrite" && Array.isArray(input.todos)) {
            this.tasks.clear();
            input.todos.forEach((t, i) => this.tasks.set(String(i + 1), { id: String(i + 1), subject: t.content, activeForm: t.activeForm, status: t.status }));
            this.emitTasks();
        }
    }

    // Final content of a message (also the only source when replaying transcripts)
    handleAssistant(message, parent) {
        if (!message) return;
        const streamed = this.cur && this.cur.msgId === message.id;
        const counts = streamed ? this.cur.counts : {};
        const streamedOfKind = kind => (streamed ? [...this.cur.blocks.values()].filter(i => i.kind === kind) : []);
        for (const b of message.content || []) {
            if (b.type === "text") {
                const n = (counts.text = (counts.text || 0) + 1);
                const item = streamedOfKind("text")[n - 1] || this.add({ kind: "text", text: "", done: true }, parent);
                item.text = b.text;
                item.done = true;
                this.touch(item);
            } else if (b.type === "thinking" || b.type === "redacted_thinking") {
                const item = (streamed && this.cur.thinking) || this.add({ kind: "thinking", text: "", tokens: 0, done: true }, parent);
                if (b.thinking) item.text = b.thinking;
                item.done = true;
                this.touch(item);
            } else if (b.type === "tool_use" || b.type === "server_tool_use") {
                let item = this.toolItems.get(b.id);
                if (!item) {
                    item = this.add({ kind: "tool", toolId: b.id, name: b.name, title: "", input: {}, inputJson: "", status: "running", output: "", diff: null }, parent);
                    this.toolItems.set(b.id, item);
                }
                this.setToolInput(item, b.input || {});
                this.touch(item);
            }
        }
    }

    handleUser(e, parent) {
        const content = e.message?.content;
        const structured = e.tool_use_result ?? e.toolUseResult;
        if (Array.isArray(content) && content.some(b => b.type === "tool_result")) {
            for (const b of content) {
                if (b.type !== "tool_result") continue;
                const item = this.toolItems.get(b.tool_use_id);
                if (!item) continue;
                item.status = item.status === "denied" ? "denied" : b.is_error ? "error" : "ok";
                // It ran, so it was allowed (replays do not contain our answers)
                if (item.permission?.state === "pending") {
                    this.permissions.delete(item.permission.requestId);
                    item.permission.state = "allowed";
                }
                item.output = truncate(resultText(b.content));
                if (structured && typeof structured === "object") {
                    if (Array.isArray(structured.structuredPatch) && structured.structuredPatch.length)
                        item.diff = diffFromPatch(structured.filePath || item.input.file_path, structured.structuredPatch);
                    if (item.name === "TaskCreate" && structured.task?.id) {
                        this.tasks.set(String(structured.task.id), { id: String(structured.task.id), subject: structured.task.subject || item.input.subject, activeForm: item.input.activeForm, status: "pending" });
                        this.emitTasks();
                    }
                }
                this.touch(item);
            }
            return;
        }
        if (e.isMeta || e.isCompactSummary) return;
        if (e.isReplay && this.echoes > 0) {
            this.echoes--;
            this.cur = null;
            return;
        }
        const text = typeof content === "string" ? content : resultText(content);
        if (!text.trim()) return;
        const peer = text.match(PEER_RE);
        if (peer) return void this.add({ kind: "peer", from: peer[1], text: peer[2].trim() });
        const out = text.match(STDOUT_RE);
        if (out) return void (out[1].trim() && this.add({ kind: "system", level: "info", text: out[1].trim() }));
        const cmd = text.match(CMD_RE);
        if (cmd) {
            // A cleared conversation starts with the /clear that created it
            if (cmd[1] === "/clear") return;
            return void this.add({ kind: "user", text: `${cmd[1]} ${cmd[2] ?? ""}`.trim() }, parent);
        }
        if (/^<(system-reminder|task-notification|local-command-caveat)/.test(text.trim())) return;
        const images = Array.isArray(content) ? content.filter(b => b.type === "image").length : 0;
        this.add({ kind: "user", text, images }, parent);
        this.cur = null;
    }

    handleResult(e) {
        this.cur = null;
        // Thinking never got a closing block (e.g. interrupted)
        for (const it of this.items) if (it.kind === "thinking" && !it.done) {
            it.done = true;
            this.touch(it);
        }
        const usage = e.usage || {};
        this.add({
            kind: "result",
            ok: !e.is_error && e.subtype === "success",
            subtype: e.subtype,
            durationMs: e.duration_ms || 0,
            turns: e.num_turns || 0,
            costUsd: e.total_cost_usd || 0,
            tokens: (usage.input_tokens || 0) + (usage.output_tokens || 0) + (usage.cache_read_input_tokens || 0) + (usage.cache_creation_input_tokens || 0),
            text: e.is_error ? truncate(e.result || (e.errors || []).join("\n"), 600) : "",
        });
        this.setMeta({ status: this.permissions.size ? "waiting" : "idle", statusText: "" });
    }

    handleControlRequest(e) {
        const r = e.request || {};
        if (r.subtype === "can_use_tool") {
            // Usually the tool card is already on screen: ask right on it
            const tool = r.tool_use_id && this.toolItems.get(r.tool_use_id);
            if (tool) {
                tool.permission = {
                    requestId: e.request_id,
                    description: r.description || "",
                    canAlways: Array.isArray(r.permission_suggestions) && r.permission_suggestions.length > 0,
                    state: "pending",
                };
                this.touch(tool);
                this.permissions.set(e.request_id, { request: r, itemId: tool.id });
                this.setMeta({ status: "waiting" });
                return;
            }
            const item = this.add({
                kind: "permission",
                requestId: e.request_id,
                toolName: r.display_name || r.tool_name,
                title: toolTitle(r.tool_name, r.input),
                description: r.description || "",
                command: r.tool_name === "Bash" ? r.input?.command || "" : "",
                diff: diffFromInput(r.tool_name, r.input || {}),
                canAlways: Array.isArray(r.permission_suggestions) && r.permission_suggestions.length > 0,
                state: "pending",
            });
            this.permissions.set(e.request_id, { request: r, itemId: item.id });
            this.setMeta({ status: "waiting" });
            return;
        }
        // Nothing else is registered by this host
        this.write({ type: "control_response", response: { subtype: "error", request_id: e.request_id, error: `unsupported: ${r.subtype}` } });
    }

    loadHistory() {
        const file = findTranscript(this.meta.sessionId);
        if (!file) return;
        const lines = fs.readFileSync(file, "utf8").split("\n");
        for (const line of lines) {
            if (!line) continue;
            let r;
            try {
                r = JSON.parse(line);
            } catch {
                continue;
            }
            if (r.isSidechain) continue;
            if (r.type === "assistant") this.handleAssistant(r.message, null);
            else if (r.type === "user") this.handleUser(r, null);
            else if (r.type === "system" && r.subtype === "compact_boundary") this.add({ kind: "system", level: "info", text: "Conversation compacted" });
        }
        for (const it of this.items) {
            if (it.kind === "tool" && it.status === "running") it.status = "ok";
            if (it.kind === "thinking") it.done = true;
        }
        if (this.items.length > HISTORY_ITEMS) {
            const cut = this.items.length - HISTORY_ITEMS;
            for (const it of this.items.slice(0, cut)) this.byId.delete(it.id);
            this.items = this.items.slice(cut);
            this.items.unshift({ id: `${this.key.slice(0, 8)}-trimmed`, kind: "system", level: "info", text: `${cut} earlier items not shown` });
            this.byId.set(this.items[0].id, this.items[0]);
        }
        this.cur = null;
        this.dirty.clear();
    }
}

// ---------- session list (all projects) ----------

const metaCache = new Map(); // file -> {mtimeMs, size, meta}
const NOISE_RE = /^<(local-command-|command-|system-reminder|task-notification)/;

function promptText(r) {
    const c = r.message?.content;
    const text = typeof c === "string" ? c : resultText(c);
    const cmd = text.match(CMD_RE);
    if (cmd) return `${cmd[1]} ${cmd[2] ?? ""}`.trim();
    return NOISE_RE.test(text.trim()) ? "" : text.trim();
}

function transcriptMeta(file) {
    const st = fs.statSync(file);
    const hit = metaCache.get(file);
    if (hit && hit.mtimeMs === st.mtimeMs && hit.size === st.size) return hit.meta;
    const meta = { id: path.basename(file, ".jsonl"), title: "", aiTitle: "", cwd: "", firstPrompt: "", messages: 0, mtime: st.mtimeMs / 1000 };
    for (const line of fs.readFileSync(file, "utf8").split("\n")) {
        if (!line) continue;
        let r;
        try {
            r = JSON.parse(line);
        } catch {
            continue;
        }
        if (r.type === "agent-name") meta.title = r.agentName || meta.title;
        else if (r.type === "custom-title") meta.title = r.customTitle || r.title || meta.title;
        else if (r.type === "ai-title") meta.aiTitle = r.aiTitle || meta.aiTitle;
        else if ((r.type === "user" || r.type === "assistant") && !r.isSidechain) {
            if (!meta.cwd && r.cwd) meta.cwd = r.cwd;
            if (r.type === "user" && !meta.firstPrompt && !r.isMeta) meta.firstPrompt = promptText(r).slice(0, 200);
            meta.messages++;
        }
    }
    meta.title = meta.title || meta.aiTitle || meta.firstPrompt.slice(0, 60) || meta.id.slice(0, 8);
    delete meta.aiTitle;
    metaCache.set(file, { mtimeMs: st.mtimeMs, size: st.size, meta });
    return meta;
}

function liveSessions(callback) {
    execFile(CLAUDE, ["agents", "--json"], { timeout: 10000 }, (err, stdout) => {
        const live = {};
        try {
            for (const a of JSON.parse(stdout)) if (a.sessionId) live[a.sessionId] = a;
        } catch {}
        callback(live);
    });
}

function listSessions(callback) {
    const files = [];
    try {
        for (const dir of fs.readdirSync(PROJECTS))
            for (const f of fs.readdirSync(path.join(PROJECTS, dir)))
                if (f.endsWith(".jsonl")) files.push(path.join(PROJECTS, dir, f));
    } catch {}
    liveSessions(live => {
        const list = [];
        for (const f of files) {
            let m;
            try {
                m = transcriptMeta(f);
            } catch {
                continue;
            }
            if (m.messages === 0) continue;
            const a = live[m.id];
            list.push({ ...m, live: !!a, kind: a?.kind || "", state: a?.state || "", shortId: a?.id || "" });
        }
        list.sort((x, y) => y.mtime - x.mtime);
        callback(list.slice(0, 60));
    });
}

// Delete a stopped session: its transcript, sidecar folder and task list.
// Background jobs also get `claude rm`; plain sessions just answer "No job matching".
function deleteSession(id, protect, callback) {
    const fail = error => callback({ ok: false, error });
    if (!/^[0-9a-f-]{36}$/.test(id)) return fail("not a session id");
    if (id === protect) return fail("this is the default session");
    if ([...sessions.values()].some(s => s.meta.sessionId === id && s.proc)) return fail("the session is open in the sidebar");
    const file = findTranscript(id);
    if (!file) return fail("no such session");
    liveSessions(live => {
        if (live[id]) return fail(`the session is running (${live[id].kind}); stop it first`);
        execFile(CLAUDE, ["rm", id.slice(0, 8)], { timeout: 30000 }, () => {
            for (const target of [file, file.slice(0, -".jsonl".length), path.join(CLAUDE_DIR, "tasks", id)])
                fs.rmSync(target, { recursive: true, force: true });
            metaCache.delete(file);
            log("deleted session", id);
            callback({ ok: true });
        });
    });
}

// ---------- ops ----------

function session(key) {
    const s = sessions.get(key);
    if (!s) throw new Error(`no session ${key}`);
    return s;
}

const ops = {
    hello(m, client) {
        client.write(JSON.stringify({ ev: "hello", version: VERSION, sessions: [...sessions.values()].map(s => s.meta) }) + "\n");
    },
    open(m) {
        let s = sessions.get(m.key);
        if (!s) {
            s = new Session({ key: m.key, sessionId: m.sessionId, cwd: m.cwd, name: m.name, model: m.model, fork: m.fork, mode: m.mode });
            sessions.set(m.key, s);
            if (!m.fresh) s.loadHistory();
        }
        if (!s.proc && !s.replay) s.start(!!m.fresh);
        broadcast({ ev: "meta", key: s.key, meta: s.meta });
    },
    subscribe(m, client) {
        const s = sessions.get(m.key);
        if (s) client.write(JSON.stringify(s.snapshot()) + "\n");
    },
    send(m) {
        session(m.key).send(m.text || "", m.images);
    },
    interrupt(m) {
        const s = session(m.key);
        s.control({ subtype: "interrupt" });
        for (const [id] of s.permissions) s.answerPermission(id, "deny");
    },
    permission(m) {
        session(m.key).answerPermission(m.requestId, m.decision);
    },
    setModel(m) {
        const s = session(m.key);
        s.control({ subtype: "set_model", model: m.model }).then(() => s.setMeta({ model: m.model }));
    },
    setMode(m) {
        const s = session(m.key);
        s.control({ subtype: "set_permission_mode", mode: m.mode }).then(() => s.setMeta({ permissionMode: m.mode }));
    },
    reset(m) {
        const old = session(m.key);
        old.kill();
        const s = new Session({ key: m.key, sessionId: m.sessionId, cwd: old.meta.cwd, name: old.meta.name, mode: old.meta.permissionMode || old.meta.requestedMode });
        sessions.set(m.key, s);
        s.start(true);
        broadcast(s.snapshot());
    },
    close(m) {
        const s = sessions.get(m.key);
        if (!s) return;
        s.kill();
        sessions.delete(m.key);
        broadcast({ ev: "closed", key: m.key });
    },
    record(m) {
        session(m.key).record = m.file || null;
    },
    replay(m) {
        sessions.get(m.key)?.kill();
        const s = new Session({ key: m.key, sessionId: "", cwd: "", name: "" });
        s.replay = true;
        sessions.set(m.key, s);
        for (const line of fs.readFileSync(m.file, "utf8").split("\n")) {
            if (!line.trim()) continue;
            try {
                s.handle(JSON.parse(line));
            } catch {}
        }
        if (s.timer) clearTimeout(s.timer);
        s.timer = null;
        s.dirty.clear();
        s.meta.status = s.permissions.size ? "waiting" : "idle";
        broadcast(s.snapshot());
    },
    listSessions(m, client) {
        listSessions(list => client.write(JSON.stringify({ ev: "sessionList", sessions: list }) + "\n"));
    },
    deleteSession(m, client) {
        deleteSession(m.sessionId, m.protect, r => client.write(JSON.stringify({ ev: "deleted", sessionId: m.sessionId, ...r }) + "\n"));
    },
    shutdown() {
        for (const s of sessions.values()) s.kill();
        setTimeout(() => process.exit(0), 300);
    },
};

function serve() {
    const server = net.createServer(client => {
        clients.add(client);
        client.on("error", () => {});
        client.on("close", () => clients.delete(client));
        readline.createInterface({ input: client }).on("line", line => {
            if (!line.trim()) return;
            let m;
            try {
                m = JSON.parse(line);
            } catch {
                return;
            }
            const op = ops[m.op];
            if (!op) return client.write(JSON.stringify({ ev: "error", message: `unknown op ${m.op}` }) + "\n");
            try {
                op(m, client);
            } catch (e) {
                client.write(JSON.stringify({ ev: "error", message: `${m.op}: ${e.message}` }) + "\n");
            }
        });
    });
    server.listen(SOCK, () => log("listening", SOCK, "claude:", CLAUDE));
}

// One host per user: if the socket answers, leave it be.
const probe = net.connect(SOCK);
probe.on("connect", () => {
    probe.end();
    process.exit(0);
});
probe.on("error", () => {
    try {
        fs.unlinkSync(SOCK);
    } catch {}
    serve();
});

// A bug in one session must not take the others down
process.on("uncaughtException", e => log("uncaught", e.stack || e));

for (const sig of ["SIGTERM", "SIGINT"])
    process.on(sig, () => {
        for (const s of sessions.values()) s.kill();
        try {
            fs.unlinkSync(SOCK);
        } catch {}
        process.exit(0);
    });
