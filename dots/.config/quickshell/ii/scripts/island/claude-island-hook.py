#!/usr/bin/env python3
"""Claude Code hook that forwards session events to the Dynamic Island in the ii bar.

Reads the hook JSON from stdin, maps it to an island event and sends it to
`qs -c ii ipc call island claude <json>` in the background. Stdlib only, never
raises, always returns/exits 0 and prints nothing to stdout.
"""
import json
import os
import re
import subprocess
import sys
import time

MAX_HOPS = 64
DETAIL_MAX = 60
EVENTS = {
    "UserPromptSubmit": "start",
    "PreToolUse": "tool",
    "Notification": "perm",
    "Stop": "stop",
    "SessionEnd": "end",
}
DETAIL_KEYS = ("command", "file_path", "pattern")
SUMMARY_MAX = 72
TRANSCRIPT_TAIL = 65536  # bytes read from the end of the transcript


def state_dir(env):
    base = env.get("XDG_RUNTIME_DIR")
    if base:
        return os.path.join(base, "claude-island")
    return "/tmp/claude-island-%d" % os.getuid()


def safe_name(session_id):
    return re.sub(r"[^A-Za-z0-9_.-]", "_", session_id)[:128]


def build_payload(hook, state, now_ms):
    """Map a Claude Code hook dict to an island payload, or None to skip."""
    if not isinstance(hook, dict):
        return None
    event = EVENTS.get(hook.get("hook_event_name"))
    if event is None:
        return None
    session_id = hook.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return None

    payload = {
        "event": event,
        "sessionId": session_id,
        "cwd": str(hook.get("cwd") or ""),
    }
    if isinstance(state.get("pid"), int):
        payload["pid"] = state["pid"]

    if event == "tool":
        payload["tool"] = str(hook.get("tool_name") or "")
        tool_input = hook.get("tool_input")
        detail = ""
        if isinstance(tool_input, dict):
            for key in DETAIL_KEYS:
                value = tool_input.get(key)
                if isinstance(value, str) and value:
                    detail = value[:DETAIL_MAX]
                    break
        payload["detail"] = detail
    elif event == "perm":
        message = hook.get("message")
        message = message if isinstance(message, str) else str(message or "")
        notification_type = hook.get("notification_type")
        lowered = message.lower()
        if notification_type == "idle_prompt" or "waiting for your input" in lowered:
            return None
        if notification_type == "permission_prompt":
            pass
        elif not notification_type and "permission" in lowered:
            pass
        else:
            return None
        payload["detail"] = message
    elif event == "stop":
        start = state.get("startMs")
        if isinstance(start, (int, float)) and not isinstance(start, bool):
            payload["elapsedMs"] = max(0, int(now_ms - start))
        summary = summarize(last_assistant_text(hook))
        if summary:
            payload["summary"] = summary

    return payload


def last_assistant_text(hook):
    """Claude's final message: from the hook input if present, else the transcript tail."""
    text = hook.get("last_assistant_message")
    if isinstance(text, str) and text.strip():
        return text
    path = hook.get("transcript_path")
    if not isinstance(path, str) or not path:
        return ""
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - TRANSCRIPT_TAIL))
            lines = f.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return ""
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        msg = entry.get("message") if isinstance(entry, dict) else None
        if not isinstance(msg, dict) or msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        if isinstance(content, str) and content.strip():
            return content
        if isinstance(content, list):
            parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
            joined = "\n".join(p for p in parts if p.strip())
            if joined:
                return joined
    return ""


def summarize(text):
    """First sentence of the first non-empty line, markdown stripped, capped in length."""
    for line in text.splitlines():
        line = re.sub(r"[*_`#>]+", "", line).strip()
        if line:
            break
    else:
        return ""
    m = re.match(r"(.+?[.!?])(\s|$)", line)
    sentence = m.group(1) if m else line
    if len(sentence) > SUMMARY_MAX:
        sentence = sentence[: SUMMARY_MAX - 1].rstrip() + "…"
    return sentence


def read_ppid(pid):
    """Parent pid from /proc/<pid>/stat, or None. comm may contain spaces, so split after the last ')'."""
    try:
        with open("/proc/%d/stat" % pid) as f:
            data = f.read()
        fields = data[data.rindex(")") + 2:].split()
        return int(fields[1])
    except Exception:
        return None


def find_terminal_pid(start_pid, client_pids, read_ppid):
    """Walk the ppid chain from start_pid until a pid is a Hyprland client pid."""
    pid = start_pid
    for _ in range(MAX_HOPS):
        if pid is None:
            return None
        if pid in client_pids:
            return pid
        if pid <= 1:
            return None
        pid = read_ppid(pid)
    return None


def get_client_pids(env):
    try:
        result = subprocess.run(
            ["hyprctl", "clients", "-j"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=1,
            env=env,
        )
        clients = json.loads(result.stdout)
        return {
            c["pid"]
            for c in clients
            if isinstance(c, dict) and isinstance(c.get("pid"), int)
        }
    except Exception:
        return set()


def load_state(path):
    try:
        with open(path) as f:
            state = json.load(f)
        return state if isinstance(state, dict) else {}
    except Exception:
        return {}


def save_state(path, state):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, path)


def send(payload, env):
    try:
        subprocess.Popen(
            ["qs", "-c", "ii", "ipc", "call", "island", "claude", json.dumps(payload)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            env=env,
        )
    except Exception:
        pass


def main(stdin, env=None):
    try:
        if env is None:
            env = os.environ
        raw = stdin.read() if hasattr(stdin, "read") else stdin
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8", "replace")
        hook_data = json.loads(raw)
        if not isinstance(hook_data, dict):
            return 0

        directory = state_dir(env)
        if env.get("CLAUDE_ISLAND_DEBUG") == "1":
            os.makedirs(directory, mode=0o700, exist_ok=True)
            with open(os.path.join(directory, "last.json"), "w") as f:
                f.write(raw)

        event = EVENTS.get(hook_data.get("hook_event_name"))
        session_id = hook_data.get("session_id")
        if event is None or not isinstance(session_id, str) or not session_id:
            return 0

        now_ms = int(time.time() * 1000)
        path = os.path.join(directory, safe_name(session_id) + ".json")
        state = load_state(path)
        if event == "start":
            state["startMs"] = now_ms
        if event != "end" and "pid" not in state:
            pid = find_terminal_pid(os.getppid(), get_client_pids(env), read_ppid)
            if pid is not None:
                state["pid"] = pid

        payload = build_payload(hook_data, state, now_ms)

        if event == "end":
            try:
                os.remove(path)
            except OSError:
                pass
        else:
            os.makedirs(directory, mode=0o700, exist_ok=True)
            save_state(path, state)

        if payload is not None:
            send(payload, env)
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.stdin, os.environ))
