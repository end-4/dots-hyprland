---
title: Configuration
description: How to customize Hyprland config, Quickshell settings, and fork-specific features
---

## Configuration layers

This fork has three layers of configuration:

1. **Upstream defaults** — `dots/.config/hypr/hyprland/` and `dots/.config/quickshell/ii/` (may be overwritten on update)
2. **Custom Hyprland config** — `dots/.config/hypr/custom/` (safe from upstream updates)
3. **Runtime settings** — `~/.config/quickshell/ii/config.json` (modified via Settings app or manually)

Always make your changes in the **custom** layer or via **runtime settings** to survive updates.

## Hyprland configuration (Lua)

Since the upstream Lua migration (PR #3269), all Hyprland config uses `.lua` files with the `hl.*` API.

### Custom config files

Located in `dots/.config/hypr/custom/` (live at `~/.config/hypr/custom/`):

| File | Purpose |
|------|---------|
| `keybinds.lua` | Your custom keybindings |
| `execs.lua` | Autostart applications |
| `env.lua` | Environment variables |
| `general.lua` | General Hyprland settings |
| `rules.lua` | Window and workspace rules |
| `variables.lua` | Custom variables |

### Lua API reference

```lua
-- Keybinds
hl.bind("SUPER", "W", hl.dsp.global("quickshell:panelFamilyCycle"),
  {description = "Cycle panel family"})
hl.bind("SUPER", "B", hl.dsp.exec_cmd("firefox"),
  {description = "Browser"})

-- Autostart (exec-once equivalent)
hl.on("hyprland.start", function()
    hl.exec_cmd("nohup ollama serve > /dev/null 2>&1 &")
end)

-- Run on every reload (exec equivalent)
hl.exec_cmd("some-command")

-- Environment variables
hl.env("EDITOR", "nvim")

-- Config sections
hl.config({
    general = { border_size = 2 },
    decoration = { rounding = 12 }
})

-- Window rules
hl.window_rule({
    rule = "opacity 0.89 override 0.89 override",
    match = "class:.*"
})

-- Monitor config
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1"
})
```

### Example: adding a keybind

Edit `~/.config/hypr/custom/keybinds.lua`:
```lua
hl.bind("SUPER + SHIFT", "F", hl.dsp.exec_cmd("firefox --private-window"),
  {description = "Private browser"})
```

## Quickshell / Shell settings

### Settings app

Open with `Super + I` or:
```bash
qs -p ~/.config/quickshell/ii/settings.qml
```

Configurable options include:
- Bar appearance (position, style, widgets, screen list)
- Colors and transparency
- Font settings
- AI model configuration
- Widget settings

### Manual config editing

The Quickshell config lives at `~/.config/quickshell/ii/config.json`. Key sections:

```json
{
  "panelFamily": "ii",
  "bar": {
    "position": "top",
    "screenList": []
  },
  "ai": {
    "model": "gemini",
    "provider": "ollama"
  }
}
```

:::caution
Edit `config.json` while Quickshell is **not** running, or use the Settings app which handles persistence correctly. Direct edits while running may be overwritten.
:::

## Custom additions (dots/custom/)

The `dots/custom/` directory contains shell scripts that run during `./setup install`:

| File | Function | Purpose |
|------|----------|---------|
| `packages.sh` | `custom_packages()` | Extra packages to install |
| `files.sh` | `custom_files()` | Extra files to copy to \$HOME |
| `commands.sh` | `custom_commands()` | Arbitrary shell commands |
| `misc.sh` | `custom_misc()` | Symlinks, env vars, etc. |

### Adding packages

Edit `dots/custom/packages.sh`:
```bash
custom_packages() {
    firefox
    vlc
    obs-studio
}
```

### Copying config files

1. Place files in `dots/custom/files/.config/...`
2. Edit `dots/custom/files.sh`:
```bash
custom_files() {
    rsync_dir "dots/custom/files" "$HOME"
}
```

## AI prompt customization

AI assistant prompts are in `dots/.config/quickshell/ii/defaults/ai/prompts/`:

| Prompt | Personality |
|--------|------------|
| `ii-Default.md` | Helpful assistant with casual tone |
| `ii-Imouto.md` | Japanese imouto personality |
| `nyarch-Acchan.md` | Nyarch Linux personality |
| `w-FourPointedSparkle.md` | Waffle panel personality |
| `NoPrompt.md` | Raw model behavior |

Available template variables: `{DISTRO}`, `{DE}`, `{DATETIME}`, `{WINDOWCLASS}`.

## Color scheme

Colors are auto-generated from your wallpaper using matugen (Material Design 3):

```bash
# Regenerate colors manually
~/.config/quickshell/ii/scripts/colors/switchwall.sh /path/to/wallpaper
```

The color system uses 5 elevation layers (0–4) with transparency auto-calculated from wallpaper vibrancy. Override in `Appearance.qml` for development.
