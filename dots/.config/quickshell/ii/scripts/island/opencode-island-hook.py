#!/usr/bin/env python3
"""OpenCode -> Dynamic Island watcher.

Long-running: follows OpenCode's server event stream (/api/event) and forwards
session state with `qs -c ii ipc call island opencode <json>`. Started by the
user unit scripts/island/opencode-island.service.

Only the event types in ROUTES are requested, so streamed text and tool-input
deltas never reach this process. Set CLAUDE_ISLAND_DEBUG=1 to log each event type.
"""

import base64
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ISLAND_CMD = ["qs", "-c", "ii", "ipc", "call", "island", "opencode"]
DEFAULT_URL = "http://127.0.0.1:49374"
RETRY_SECONDS = 3

# OpenCode 2.x event type -> island event.
ROUTES = {
    "session.created": "created",  # only read to learn which sessions are subagents
    "session.execution.started": "start",
    "session.tool.input.started": "tool",
    "session.step.started": "resume",  # next model step: clears a retry or compaction
    "permission.asked": "perm",
    "permission.replied": "resume",  # the prompt is answered: back to working
    "form.created": "ask",  # the agent asks the user a question
    "form.replied": "resume",
    "form.cancelled": "resume",
    "session.retry.scheduled": "retry",  # provider error / rate limit, retrying later
    "session.compaction.started": "compact",
    "session.compaction.ended": "resume",
    "session.compaction.failed": "resume",
    "session.execution.succeeded": "stop",
    "session.execution.failed": "stop",
    "session.execution.interrupted": "end",
    "session.archived": "end",
    "session.deleted": "end",
}


# Answers to an open prompt or question: the only resumes that may clear "asking".
ANSWERS = {"permission.replied", "form.replied", "form.cancelled"}
# Busy states that must not cover an open prompt or question.
BUSY = {"tool", "retry", "compact", "resume"}


def subscribed_types():
    return list(ROUTES)


def log(message):
    print(f"[opencode-island] {message}", file=sys.stderr, flush=True)


def service_path(env):
    state_home = env.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return str(Path(state_home) / "opencode" / "service.json")


def load_service(path, env):
    """Return (url, password), or None while no credentials exist."""
    try:
        with open(path) as f:
            service = json.load(f)
    except (OSError, ValueError):
        service = {}
    if not isinstance(service, dict):
        service = {}
    password = service.get("password") or env.get("OPENCODE_PASSWORD", "")
    if not password:
        return None
    return service.get("url") or DEFAULT_URL, password


def error_summary(error):
    message = ""
    if isinstance(error, dict):
        nested = error.get("data")
        message = error.get("message") or (nested.get("message") if isinstance(nested, dict) else "")
    elif isinstance(error, str):
        message = error
    return str(message or "Opencode run failed")[:100]


class Family:
    """OpenCode runs each subagent as its own session with a parent."""

    def __init__(self):
        self.parents = {}  # subagent session -> parent session
        self.asking = set()  # top-level sessions with a permission prompt open

    def top(self, sid):
        seen = set()
        while sid in self.parents and sid not in seen:
            seen.add(sid)
            sid = self.parents[sid]
        return sid


def subagent_reaches_island(island_event, kind, top, started, family):
    """A subagent is part of its parent's run: only what the user should see gets through."""
    if island_event in ("perm", "ask"):
        return True
    if top not in started:  # the run already ended; a late event must not bring it back
        return False
    # Its tool calls, retries and compactions keep the run up to date; its own start and
    # finish are not the run's (the "asking" check happens for every session later).
    return island_event in BUSY


def event_to_payload(event, started, now_ms, family=None):
    """Map one OpenCode event to an island payload, or None to ignore it.

    `started` maps session id -> start time and `family` tracks subagents; both are updated here.
    """
    family = family if family is not None else Family()
    kind = event.get("type")
    island_event = ROUTES.get(kind)
    data = event.get("data")
    if island_event is None or not isinstance(data, dict):
        return None
    form = data.get("form") if isinstance(data.get("form"), dict) else {}
    sid = form.get("sessionID") or data.get("sessionID")
    if not sid:
        return None

    if island_event == "created":
        info = data.get("info")  # older event shape
        parent = data.get("parentID") or (info.get("parentID") if isinstance(info, dict) else None)
        if parent:
            family.parents[sid] = parent
        return None

    top = family.top(sid)
    if top != sid:
        if kind == "session.deleted":
            family.parents.pop(sid, None)
        if not subagent_reaches_island(island_event, kind, top, started, family):
            return None
        sid = top

    if island_event == "resume" and sid not in started:
        return None  # nothing to go back to (the run ended or was never seen)
    if kind in ANSWERS or island_event in ("stop", "end"):
        family.asking.discard(sid)
    elif island_event in BUSY and sid in family.asking:
        return None  # keep the "?" up until the user answers
    if island_event in ("perm", "ask"):
        family.asking.add(sid)
    if island_event != "resume":
        started.setdefault(sid, now_ms)
    payload = {
        "event": "start" if island_event == "resume" else island_event,
        "sessionId": sid,
        "elapsedMs": now_ms - started.get(sid, now_ms),
    }
    if island_event == "tool":
        payload["tool"] = str(data.get("name") or "")
    elif island_event == "perm":
        resources = data.get("resources")
        payload["tool"] = str(data.get("action") or "")
        payload["detail"] = str(resources[0] if isinstance(resources, list) and resources else "")[:100]
    elif island_event == "ask":
        payload["detail"] = str(form.get("title") or "")[:100]
    elif island_event == "retry":
        payload["attempt"] = data.get("attempt") if isinstance(data.get("attempt"), int) else 0
        payload["retryAt"] = data.get("at") if isinstance(data.get("at"), int) else 0
        payload["summary"] = error_summary(data.get("error"))
    if kind == "session.execution.failed":
        payload["failed"] = True
        payload["summary"] = error_summary(data.get("error"))
    if island_event in ("stop", "end"):
        started.pop(sid, None)
    return payload


def parse_sse_line(line):
    """Return the JSON object on an SSE `data:` line, or None for anything else."""
    if not line.startswith(b"data:"):
        return None
    try:
        event = json.loads(line[5:].decode("utf-8"))
    except ValueError:
        return None
    return event if isinstance(event, dict) else None


def send_island(payload):
    """Deliver one payload. The island being down is not an error."""
    try:
        subprocess.run(ISLAND_CMD + [json.dumps(payload)], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=3, check=False)
    except (OSError, subprocess.SubprocessError):
        pass


def watch_once(requests, url, password, started, family):
    """Follow the stream until the connection ends."""
    token = base64.b64encode(f"opencode:{password}".encode()).decode()
    headers = {"Authorization": f"Basic {token}", "Accept": "text/event-stream"}
    params = {"types": subscribed_types()}
    with requests.get(f"{url}/api/event", headers=headers, params=params,
                      stream=True, timeout=(5, None)) as response:
        if response.status_code != 200:
            log(f"HTTP {response.status_code}: {response.text[:200]}")
            return
        log("watching for events")
        # chunk_size=1: hand over each line as soon as it arrives. Only a few events per
        # second are subscribed, and iter_lines keeps events that span network reads whole.
        for line in response.iter_lines(chunk_size=1):
            event = parse_sse_line(line)
            if event is None:
                continue
            if os.environ.get("CLAUDE_ISLAND_DEBUG"):
                log(f"event {event.get('type')}")
            payload = event_to_payload(event, started, int(time.time() * 1000), family)
            if payload is not None:
                send_island(payload)


def main():
    try:
        import requests
    except ImportError:
        log("python-requests is not installed")
        return 1

    started = {}
    family = Family()
    while True:
        # Re-read every time: OpenCode writes new credentials when its server restarts.
        service = load_service(service_path(os.environ), os.environ)
        if service is not None:
            try:
                watch_once(requests, service[0], service[1], started, family)
            except (requests.exceptions.RequestException, OSError) as e:
                log(f"connection lost: {e}")
        time.sleep(RETRY_SECONDS)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
