# Orbitbar Agent HUD

This branch adds a Quickshell-integrated agent HUD to the `ii` shell.

## What it includes
- `Orbitbar` in the top bar with a pop-down thread feed
- a local bridge daemon that watches live terminal AI sessions
- CLI-first AI sidebar support for `codex`, `gemini`, `claude`, plus Kimi variants already wired in the current sidebar service
- terminal handoff actions for Hyprland, including `special:agents`

## Expected local tools
- `quickshell`
- `hyprctl`
- a supported terminal such as `kitty`
- local CLI tools you want Orbitbar to watch:
  - `gemini`
  - `codex`
  - `claude`

## Runtime behavior
- Orbitbar state lives under `~/.local/state/quickshell/user/orbitbar`
- the bridge writes:
  - `state.json`
  - `orbitbar.sock`
- live agent terminals are routed to `special:agents`
- sensitive approval flows stay in the terminal; Orbitbar is the decision/jump surface

## Reloading and testing
- reload the shell with your normal Quickshell flow
- Orbitbar is initialized from `shell.qml` via `Orbitbar.load()`
- if you want to send synthetic events during development, use:
  - `dots/.config/quickshell/ii/scripts/orbitbar/send_event.py`

## Sharing notes
- this branch is meant for review and collaboration, not upstream submission
- the source tree here is the tracked repo version of the live `~/.config/quickshell/ii` changes
