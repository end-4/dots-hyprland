#!/usr/bin/env python3
from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import subprocess
import signal
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


def now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def compact_text(value: str, limit: int = 80) -> str:
    text = " ".join(value.split())
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "…"


@dataclass
class SessionState:
    session_id: str
    payload: dict[str, Any] = field(default_factory=dict)

    def merge(self, incoming: dict[str, Any]) -> None:
        for key, value in incoming.items():
            if key == "session_id":
                continue
            if value is None:
                self.payload.pop(key, None)
                continue
            self.payload[key] = value

        self.payload["session_id"] = self.session_id
        self.payload["updated_at"] = now_iso()

    def as_dict(self) -> dict[str, Any]:
        return dict(self.payload)


class OrbitbarBridge:
    def __init__(self, socket_path: Path, state_path: Path) -> None:
        self.socket_path = socket_path
        self.state_path = state_path
        self.special_workspace_name = "agents"
        self.event_sessions: dict[str, SessionState] = {}
        self.discovered_sessions: dict[str, dict[str, Any]] = {}
        self.server: asyncio.AbstractServer | None = None
        self.discovery_task: asyncio.Task[None] | None = None

    async def start(self) -> None:
        self.socket_path.parent.mkdir(parents=True, exist_ok=True)
        self.state_path.parent.mkdir(parents=True, exist_ok=True)

        if self.socket_path.exists():
            self.socket_path.unlink()

        self.server = await asyncio.start_unix_server(
            self.handle_client,
            path=str(self.socket_path),
        )
        self.discovery_task = asyncio.create_task(self.discovery_loop())
        await self.flush_state()

    async def stop(self) -> None:
        if self.server is not None:
            self.server.close()
            await self.server.wait_closed()
            self.server = None

        if self.discovery_task is not None:
            self.discovery_task.cancel()
            try:
                await self.discovery_task
            except asyncio.CancelledError:
                pass
            self.discovery_task = None

        if self.socket_path.exists():
            self.socket_path.unlink()

    async def handle_client(
        self,
        reader: asyncio.StreamReader,
        writer: asyncio.StreamWriter,
    ) -> None:
        try:
            while True:
                line = await reader.readline()
                if not line:
                    break

                line = line.strip()
                if not line:
                    continue

                try:
                    event = json.loads(line)
                    if not isinstance(event, dict):
                        raise ValueError("event must be a JSON object")
                    self.apply_event(event)
                    await self.flush_state()
                    writer.write(b'{"ok":true}\n')
                    await writer.drain()
                except Exception as exc:  # noqa: BLE001
                    writer.write(
                        json.dumps({"ok": False, "error": str(exc)}).encode("utf-8") + b"\n"
                    )
                    await writer.drain()
        finally:
            writer.close()
            await writer.wait_closed()

    def apply_event(self, event: dict[str, Any]) -> None:
        session_id = event.get("session_id")
        if not session_id or not isinstance(session_id, str):
            raise ValueError("missing required string field: session_id")

        if event.get("remove") is True:
            self.event_sessions.pop(session_id, None)
            return

        tool = event.get("tool")
        status = event.get("status")
        if tool is None or status is None:
            raise ValueError("events must include tool and status unless remove=true")

        session = self.event_sessions.get(session_id)
        if session is None:
            session = SessionState(session_id=session_id)
            self.event_sessions[session_id] = session

        session.merge(event)

    async def flush_state(self) -> None:
        merged = self.build_merged_sessions()
        sessions = sorted(
            merged,
            key=self.sort_key,
        )

        payload = {
            "updated_at": now_iso(),
            "session_count": len(sessions),
            "sessions": sessions,
        }

        tmp_path = self.state_path.with_suffix(".tmp")
        tmp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        tmp_path.replace(self.state_path)

    def build_merged_sessions(self) -> list[dict[str, Any]]:
        merged: dict[str, dict[str, Any]] = {
            session_id: dict(payload)
            for session_id, payload in self.discovered_sessions.items()
        }

        for session_id, session in self.event_sessions.items():
            existing = merged.get(session_id, {})
            existing.update(session.as_dict())
            merged[session_id] = existing

        return list(merged.values())

    async def discovery_loop(self) -> None:
        while True:
            try:
                self.discovered_sessions = self.discover_sessions()
                await self.flush_state()
            except Exception:
                pass
            await asyncio.sleep(2.0)

    def discover_sessions(self) -> dict[str, dict[str, Any]]:
        proc = subprocess.run(
            ["ps", "-eo", "pid=,ppid=,tty=,comm=,args="],
            capture_output=True,
            text=True,
            check=True,
        )

        processes: dict[int, dict[str, Any]] = {}
        for raw_line in proc.stdout.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            pid, ppid, tty, comm, args = parts
            try:
                processes[int(pid)] = {
                    "pid": int(pid),
                    "ppid": int(ppid),
                    "tty": tty,
                    "comm": comm,
                    "args": args,
                }
            except ValueError:
                continue

        hypr_clients: dict[int, dict[str, Any]] = {}
        try:
            clients_proc = subprocess.run(
                ["hyprctl", "clients", "-j"],
                capture_output=True,
                text=True,
                check=True,
            )
            for client in json.loads(clients_proc.stdout):
                pid = client.get("pid")
                if isinstance(pid, int):
                    hypr_clients[pid] = client
        except Exception:
            hypr_clients = {}

        tool_specs = [
            ("gemini", "gemini"),
            ("codex", "codex"),
            ("claude", "claude"),
        ]
        terminal_names = {"kitty", "ghostty", "wezterm", "alacritty", "foot", "konsole"}

        discovered: dict[str, dict[str, Any]] = {}
        matched_pids: list[tuple[str, int]] = []
        gemini_projects = self.load_gemini_projects()

        for process in processes.values():
            args = process["args"].lower()
            tool_name = None
            for slug, needle in tool_specs:
                if self.matches_tool_process(process, needle):
                    tool_name = slug
                    break
            if tool_name is None:
                continue
            if tool_name == "codex" and "app-server" in args:
                continue

            matched_pids.append((tool_name, process["pid"]))

        redundant: set[int] = set()
        for tool_name, pid in matched_pids:
            current = processes.get(pid)
            visited: set[int] = set()
            while current and current["pid"] not in visited:
                visited.add(current["pid"])
                parent = processes.get(current["ppid"])
                if parent is None:
                    break
                parent_args = parent["args"].lower()
                if tool_name in parent_args and "app-server" not in parent_args:
                    redundant.add(parent["pid"])
                current = parent

        live_sessions: list[dict[str, Any]] = []

        for tool_name, pid in matched_pids:
            if pid in redundant:
                continue
            process = processes[pid]

            terminal_pid = None
            current = process
            visited: set[int] = set()
            while current and current["pid"] not in visited:
                visited.add(current["pid"])
                if current["comm"] in terminal_names:
                    terminal_pid = current["pid"]
                    break
                current = processes.get(current["ppid"])

            if terminal_pid is None:
                continue

            client = hypr_clients.get(terminal_pid) if terminal_pid else None
            cwd = ""
            try:
                cwd = os.readlink(f"/proc/{process['pid']}/cwd")
            except OSError:
                cwd = ""

            project_name = Path(cwd).name if cwd else ""
            live_sessions.append({
                "tool_name": tool_name,
                "process": process,
                "client": client,
                "terminal_pid": terminal_pid,
                "cwd": cwd,
                "project_name": project_name,
            })

        gemini_assignments = self.assign_gemini_sessions(
            [session for session in live_sessions if session["tool_name"] == "gemini"],
            gemini_projects,
        )

        for live_session in live_sessions:
            tool_name = str(live_session["tool_name"])
            process = dict(live_session["process"])
            client = live_session["client"]
            terminal_pid = live_session["terminal_pid"]
            cwd = str(live_session["cwd"])
            project_name = str(live_session["project_name"])
            workspace_name = self.ensure_terminal_in_special(client)
            title = project_name or (client.get("title", "") if client else "") or f"{tool_name} session"
            external_meta = self.build_tool_external_meta(
                tool_name=tool_name,
                process=process,
                cwd=cwd,
                project_name=project_name,
                title=title,
                gemini_assignments=gemini_assignments,
            )

            terminal_title = client.get("title", "") if client else ""
            detail = external_meta.get("detail") or "No action needed right now."
            requires_action = bool(external_meta.get("requires_action"))
            status = "monitoring"
            options: list[dict[str, Any]] = []
            preview = external_meta.get("preview")
            command_candidate = self.extract_command_candidate(external_meta)
            sensitive_input_required = self.is_sensitive_command(command_candidate)
            actions: list[dict[str, Any]] = []
            lower_terminal_title = terminal_title.lower()
            if any(token in lower_terminal_title for token in ("action required", "permission request", "approval required")):
                requires_action = True
                status = "approval_required"
                prompt_meta = self.build_action_prompt(tool_name, external_meta)
                detail = prompt_meta["detail"]
                options = prompt_meta["options"]
                preview = prompt_meta["preview"]
            elif "ask" in lower_terminal_title:
                requires_action = True
                status = "question"

            if client and client.get("address"):
                actions.append({
                    "id": "focus_terminal",
                    "label": "Enter password" if sensitive_input_required else "Jump to terminal",
                    "emphasized": bool(requires_action or sensitive_input_required),
                })

            meta_title = external_meta.get("title") or title
            provider_session_id = external_meta.get("provider_session_id")
            session_id = f"{tool_name}:{process['pid']}"

            discovered[session_id] = {
                "session_id": session_id,
                "tool": tool_name,
                "status": status,
                "title": meta_title,
                "detail": detail,
                "project": project_name or None,
                "cwd": cwd or None,
                "workspace": workspace_name,
                "terminal_app": client.get("class") if client else None,
                "terminal_title": client.get("title") if client else None,
                "window_address": client.get("address") if client else None,
                "terminal_pid": client.get("pid") if client else terminal_pid,
                "pid": process["pid"],
                "requires_action": requires_action,
                "sensitive_input_required": sensitive_input_required,
                "actions": actions,
                "options": options,
                "recent": external_meta.get("recent", []),
                "preview": preview,
                "provider": external_meta.get("provider"),
                "provider_session_id": provider_session_id,
                "age": external_meta.get("age"),
                "updated_at": now_iso(),
            }

        return discovered

    def build_tool_external_meta(
        self,
        tool_name: str,
        process: dict[str, Any],
        cwd: str,
        project_name: str,
        title: str,
        gemini_assignments: dict[int, dict[str, Any]],
    ) -> dict[str, Any]:
        base_meta: dict[str, Any] = {
            "title": title,
            "detail": "No action needed right now.",
            "preview": None,
            "recent": [],
            "provider": None,
            "provider_session_id": None,
            "age": "",
            "requires_action": False,
        }

        if tool_name == "gemini":
            base_meta.update(gemini_assignments.get(process["pid"], {}))
        elif tool_name == "claude":
            base_meta.update(self.read_claude_project_session(cwd))
        elif tool_name == "codex":
            base_meta.update(self.read_codex_project_session(cwd))

        return base_meta

    @staticmethod
    def matches_tool_process(process: dict[str, Any], needle: str) -> bool:
        args = str(process.get("args", "")).lower()
        comm = str(process.get("comm", "")).lower()
        if needle not in args:
            return False

        if comm in {"rg", "grep", "sed", "cat", "ps"}:
            return False

        if comm in {"bash", "sh", "zsh", "fish"}:
            inspection_tokens = (
                " rg ",
                " grep ",
                " sed ",
                " cat ",
                " ps -",
                "pgrep ",
                "orbitbar_bridge.py",
                "quickshell list",
                "quickshell log",
            )
            if any(token in args for token in inspection_tokens):
                return False

        return True

    def load_gemini_projects(self) -> dict[str, str]:
        path = Path.home() / ".gemini" / "projects.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            projects = payload.get("projects", {})
            if isinstance(projects, dict):
                return {str(key): str(value) for key, value in projects.items()}
        except Exception:
            pass
        return {}

    def resolve_gemini_project_alias(self, cwd: str, gemini_projects: dict[str, str]) -> str:
        if not cwd:
            return Path.home().name

        resolved_cwd = str(Path(cwd).resolve())
        best_alias = ""
        best_length = -1
        for project_path, alias in gemini_projects.items():
            try:
                resolved_project = str(Path(project_path).resolve())
            except Exception:
                continue

            if resolved_cwd == resolved_project or resolved_cwd.startswith(resolved_project + os.sep):
                if len(resolved_project) > best_length:
                    best_alias = alias
                    best_length = len(resolved_project)

        if best_alias:
            return best_alias
        return Path(cwd).name or Path.home().name

    def assign_gemini_sessions(
        self,
        live_sessions: list[dict[str, Any]],
        gemini_projects: dict[str, str],
    ) -> dict[int, dict[str, Any]]:
        assignments: dict[int, dict[str, Any]] = {}
        grouped: dict[str, list[dict[str, Any]]] = {}

        for live_session in live_sessions:
            alias = self.resolve_gemini_project_alias(str(live_session["cwd"]), gemini_projects)
            grouped.setdefault(alias, []).append(live_session)

        for alias, project_sessions in grouped.items():
            parsed_sessions = self.read_gemini_project_sessions(alias)
            project_sessions.sort(key=lambda item: self.get_process_start_ticks(int(item["process"]["pid"])))
            selected_sessions = parsed_sessions[-len(project_sessions):]
            for live_session, parsed_session in zip(project_sessions, selected_sessions):
                assignments[int(live_session["process"]["pid"])] = parsed_session

        return assignments

    def build_action_prompt(self, tool_name: str, session_meta: dict[str, Any]) -> dict[str, Any]:
        if tool_name == "gemini":
            return self.build_gemini_action_prompt(session_meta)
        return self.build_generic_action_prompt(tool_name, session_meta)

    def build_gemini_action_prompt(self, session_meta: dict[str, Any]) -> dict[str, Any]:
        command = self.extract_command_candidate(session_meta)
        if command:
            executable = command.split()[0]
            detail = f"Allow execution of: '{executable}'?"
            preview = command
        else:
            detail = "Gemini is waiting for your approval."
            preview = session_meta.get("preview")

        return {
            "detail": detail,
            "preview": preview,
            "options": [
                {
                    "id": "allow_once",
                    "label": "1. Allow once",
                    "description": "Run this command a single time.",
                },
                {
                    "id": "allow_session",
                    "label": "2. Allow for this session",
                    "description": "Keep allowing similar commands in this Gemini session.",
                },
                {
                    "id": "deny_suggest_changes",
                    "label": "3. No, suggest changes",
                    "description": "Deny execution and ask Gemini to revise the plan.",
                },
            ],
        }

    def build_generic_action_prompt(self, tool_name: str, session_meta: dict[str, Any]) -> dict[str, Any]:
        preview = self.extract_command_candidate(session_meta) or session_meta.get("preview")
        return {
            "detail": f"{tool_name.capitalize()} needs your input in the terminal.",
            "preview": preview,
            "options": [],
        }

    @staticmethod
    def is_sensitive_command(command: str) -> bool:
        stripped = command.strip().lower()
        if not stripped:
            return False
        return stripped.startswith(("sudo ", "doas ", "passwd", "su ", "pkexec "))

    def extract_command_candidate(self, session_meta: dict[str, Any]) -> str:
        candidates: list[str] = []
        preview = session_meta.get("preview")
        if isinstance(preview, str) and preview.strip():
            candidates.append(preview)

        recent = session_meta.get("recent")
        if isinstance(recent, list):
            for entry in recent:
                if isinstance(entry, str) and entry.strip():
                    candidates.append(entry)

        for candidate in candidates:
            backtick_match = re.search(r"`([^`]+)`", candidate)
            if backtick_match:
                return compact_text(backtick_match.group(1), 240)

            stripped = candidate.strip()
            if stripped.startswith(("sudo ", "pacman ", "paru ", "yay ", "npm ", "pnpm ", "bun ", "python ", "bash ", "sh ")):
                return compact_text(stripped, 240)

        return ""

    def read_gemini_project_sessions(self, project_alias: str) -> list[dict[str, Any]]:
        home = Path.home()
        gemini_root = home / ".gemini"
        chat_dir = gemini_root / "tmp" / project_alias / "chats"
        if not chat_dir.exists():
            return []

        session_files = sorted(chat_dir.glob("session-*.json"), key=lambda path: path.stat().st_mtime, reverse=True)
        if not session_files:
            return []

        parsed_sessions: list[dict[str, Any]] = []
        for path in session_files:
            try:
                payload = json.loads(path.read_text(encoding="utf-8"))
            except Exception:
                continue
            messages = payload.get("messages", [])
            if not isinstance(messages, list) or not messages:
                continue

            first_user = next((message for message in messages if message.get("type") == "user"), None)
            last_message = messages[-1]
            title = project_alias
            if first_user:
                title = compact_text(self.extract_gemini_message_text(first_user), 34) or title

            detail = "No action needed right now."
            requires_action = False
            if isinstance(last_message, dict):
                last_type = last_message.get("type")
                if last_type == "user":
                    detail = "Waiting for Gemini to respond."
                    requires_action = True
                elif last_type == "info":
                    info_text = compact_text(self.extract_gemini_message_text(last_message), 120)
                    if info_text:
                        detail = info_text

            recent = []
            for message in messages[-3:]:
                label = message.get("type", "message")
                text = compact_text(self.extract_gemini_message_text(message), 90)
                if text:
                    recent.append(f"{label}: {text}")

            preview = None
            if isinstance(last_message, dict):
                preview = compact_text(self.extract_gemini_message_text(last_message), 240)

            age = ""
            sort_timestamp = payload.get("lastUpdated") or payload.get("startTime") or ""
            if isinstance(sort_timestamp, str):
                try:
                    dt = datetime.fromisoformat(sort_timestamp.replace("Z", "+00:00"))
                    delta = datetime.now(UTC) - dt.astimezone(UTC)
                    minutes = int(delta.total_seconds() // 60)
                    if minutes < 60:
                        age = f"{max(1, minutes)}m"
                    else:
                        age = f"{max(1, minutes // 60)}h"
                except Exception:
                    age = ""

            parsed_sessions.append({
                "title": title,
                "detail": detail,
                "preview": preview,
                "recent": recent,
                "provider": "Gemini CLI",
                "provider_session_id": payload.get("sessionId"),
                "age": age,
                "requires_action": requires_action,
                "_sort_timestamp": str(sort_timestamp),
            })

        parsed_sessions.sort(key=lambda item: str(item.get("_sort_timestamp", "")))
        for session in parsed_sessions:
            session.pop("_sort_timestamp", None)
        return parsed_sessions

    def read_claude_project_session(self, cwd: str) -> dict[str, Any]:
        if not cwd:
            return {}

        project_slug = self.claude_project_slug(cwd)
        index_path = Path.home() / ".claude" / "projects" / project_slug / "sessions-index.json"
        if not index_path.exists():
            return {}

        try:
            payload = json.loads(index_path.read_text(encoding="utf-8"))
        except Exception:
            return {}

        entries = payload.get("entries", [])
        if not isinstance(entries, list) or not entries:
            return {}

        latest = max(entries, key=lambda item: int(item.get("fileMtime", 0)))
        title = compact_text(str(latest.get("firstPrompt") or Path(cwd).name or "Claude session"), 34)
        detail = compact_text(str(latest.get("summary") or "No action needed right now."), 120)
        recent = self.read_claude_recent_messages(Path(str(latest.get("fullPath", ""))))
        preview = recent[-1] if recent else None
        return {
            "title": title,
            "detail": detail,
            "preview": preview,
            "recent": recent,
            "provider": "Claude Code",
            "provider_session_id": latest.get("sessionId"),
            "age": self.relative_age_from_iso(str(latest.get("modified", ""))),
            "requires_action": False,
        }

    def read_codex_project_session(self, cwd: str) -> dict[str, Any]:
        session_index = Path.home() / ".codex" / "session_index.jsonl"
        if not session_index.exists():
            return {}

        latest: dict[str, Any] | None = None
        try:
            for raw_line in session_index.read_text(encoding="utf-8").splitlines():
                if not raw_line.strip():
                    continue
                entry = json.loads(raw_line)
                if not isinstance(entry, dict):
                    continue
                latest = entry
        except Exception:
            return {}

        if latest is None:
            return {}

        thread_name = compact_text(str(latest.get("thread_name") or Path(cwd).name or "Codex session"), 34)
        updated_at = str(latest.get("updated_at") or "")
        return {
            "title": thread_name,
            "detail": "Codex session is live in the terminal.",
            "preview": None,
            "recent": [],
            "provider": "Codex CLI",
            "provider_session_id": latest.get("id"),
            "age": self.relative_age_from_iso(updated_at),
            "requires_action": False,
        }

    @staticmethod
    def claude_project_slug(cwd: str) -> str:
        return "-" + str(Path(cwd).resolve()).strip("/").replace("/", "-")

    def read_claude_recent_messages(self, session_path: Path) -> list[str]:
        if not session_path.exists():
            return []

        recent: list[str] = []
        try:
            lines = session_path.read_text(encoding="utf-8").splitlines()
        except Exception:
            return []

        for raw_line in lines[-5:]:
            try:
                entry = json.loads(raw_line)
            except Exception:
                continue

            entry_type = str(entry.get("type", "message"))
            message = entry.get("message", {})
            if isinstance(message, dict):
                content = message.get("content")
                text = self.extract_claude_content_text(content)
            else:
                text = ""
            text = compact_text(text, 90)
            if text:
                recent.append(f"{entry_type}: {text}")

        return recent[-3:]

    @staticmethod
    def extract_claude_content_text(content: Any) -> str:
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts: list[str] = []
            for item in content:
                if isinstance(item, dict):
                    if isinstance(item.get("text"), str):
                        parts.append(item["text"])
                    elif isinstance(item.get("thinking"), str):
                        parts.append(item["thinking"])
            return "\n".join(parts)
        return ""

    def relative_age_from_iso(self, value: str) -> str:
        if not value:
            return ""
        try:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
            delta = datetime.now(UTC) - dt.astimezone(UTC)
            minutes = int(delta.total_seconds() // 60)
            if minutes < 60:
                return f"{max(1, minutes)}m"
            return f"{max(1, minutes // 60)}h"
        except Exception:
            return ""

    def ensure_terminal_in_special(self, client: dict[str, Any] | None) -> str | None:
        if not client:
            return None

        address = client.get("address")
        workspace = client.get("workspace", {}) or {}
        current_name = str(workspace.get("name") or "")
        target_name = f"special:{self.special_workspace_name}"

        if not address:
            return current_name or None

        if current_name != target_name:
            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "dispatch",
                        "movetoworkspacesilent",
                        f"{target_name},address:{address}",
                    ],
                    check=False,
                    capture_output=True,
                    text=True,
                )
            except Exception:
                pass
            return target_name

        return current_name or None

    @staticmethod
    def get_process_start_ticks(pid: int) -> int:
        try:
            with open(f"/proc/{pid}/stat", encoding="utf-8") as handle:
                stat = handle.read().split()
            return int(stat[21])
        except Exception:
            return pid

    @staticmethod
    def extract_gemini_message_text(message: dict[str, Any]) -> str:
        content = message.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts: list[str] = []
            for item in content:
                if isinstance(item, dict) and isinstance(item.get("text"), str):
                    parts.append(item["text"])
            return "\n".join(parts)
        return ""

    @staticmethod
    def sort_key(session: dict[str, Any]) -> tuple[int, str]:
        priority = {
            "approval_required": 0,
            "question": 1,
            "error": 2,
            "working": 3,
            "monitoring": 4,
            "done": 4,
            "idle": 5,
        }
        return (priority.get(str(session.get("status")), 9), str(session.get("session_id", "")))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Orbitbar local bridge daemon")
    parser.add_argument("--socket-path", required=True)
    parser.add_argument("--state-path", required=True)
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    bridge = OrbitbarBridge(
        socket_path=Path(args.socket_path),
        state_path=Path(args.state_path),
    )

    stop_event = asyncio.Event()

    def request_stop() -> None:
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, request_stop)

    await bridge.start()

    try:
        await stop_event.wait()
    finally:
        await bridge.stop()


if __name__ == "__main__":
    asyncio.run(main())
