# Dynamic Island: coding agent hooks

Optional. With **Settings → Bar → Dynamic Island → Coding agents** on, the island shows when Claude Code or
OpenCode is working (animated logo + elapsed time), waiting for you (a "?" badge), or done (a short burst).
The island only listens; these scripts are what tell it. Both are Python standard library only and never
make the agent fail (they always exit 0).

## Claude Code

`claude-island-hook.py` is a Claude Code [hook](https://docs.claude.com/en/docs/claude-code/hooks). Add this to
`~/.claude/settings.json` (merge with any `hooks` you already have):

```json
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "python3 -I ~/.config/quickshell/ii/scripts/island/claude-island-hook.py", "timeout": 5 }] }],
    "PreToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "python3 -I ~/.config/quickshell/ii/scripts/island/claude-island-hook.py", "timeout": 5 }] }],
    "Notification": [{ "matcher": "permission_prompt", "hooks": [{ "type": "command", "command": "python3 -I ~/.config/quickshell/ii/scripts/island/claude-island-hook.py", "timeout": 5 }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "python3 -I ~/.config/quickshell/ii/scripts/island/claude-island-hook.py", "timeout": 5 }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "python3 -I ~/.config/quickshell/ii/scripts/island/claude-island-hook.py", "timeout": 5 }] }]
  }
}
```

Each event takes ~35 ms. The hook finds the terminal window running Claude (so a click on the logo can focus it)
and keeps a little per-session state in `$XDG_RUNTIME_DIR/claude-island/`.

## OpenCode

`opencode-island-hook.py` is a small background watcher: it follows the OpenCode server's event stream and
forwards session state. Run it as a user service:

```bash
systemctl --user enable --now ~/.config/quickshell/ii/scripts/island/opencode-island.service
```

It reads the server address and credentials from `~/.local/state/opencode/service.json` (re-read on every
reconnect) and falls back to `http://127.0.0.1:49374`.

## Checking it works

```bash
qs -c ii ipc call island test claudeLive     # fake a working Claude session
qs -c ii ipc call island test opencodePerm   # fake OpenCode waiting for permission
qs -c ii ipc call island state               # JSON with what the island currently shows
```

For debugging, set `CLAUDE_ISLAND_DEBUG=1`: the Claude hook then writes the last raw payload to
`$XDG_RUNTIME_DIR/claude-island/last.json`, and the OpenCode watcher logs each event type it receives.
