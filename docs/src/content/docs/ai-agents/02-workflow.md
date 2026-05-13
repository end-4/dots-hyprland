---
title: Workflow
description: Step-by-step development workflows for common tasks
---

## Adding a keybind

1. Edit `dots/.config/hypr/custom/keybinds.lua`
2. Add the bind using `hl.bind()`:
   ```lua
   hl.bind("SUPER + SHIFT", "F", hl.dsp.exec_cmd("firefox --private-window"),
     {description = "Private browser"})
   ```
3. Test live by reloading Hyprland config (the file is sourced on reload)
4. Update `docs/src/content/docs/guide/03-usage.md` keybind tables
5. Add a note to `dots/custom/EDITED.md`

## Adding an autostart application

1. Edit `dots/.config/hypr/custom/execs.lua`
2. Add inside the `hl.on("hyprland.start", ...)` handler:
   ```lua
   hl.on("hyprland.start", function()
       hl.exec_cmd("your-app --flag")
   end)
   ```
3. For apps that should restart on config reload, put `hl.exec_cmd()` outside the handler
4. Update `docs/src/content/docs/guide/04-configuration.md` if it's a notable addition

## Adding a Quickshell service

1. Create `dots/.config/quickshell/ii/services/YourService.qml`
2. Make it a singleton with the required interface:
   ```qml
   pragma Singleton
   import QtQuick

   QtObject {
       // IPC handler for external control
       IpcHandler {
           target: "yourService"
           function call(args) {
               // Handle IPC calls
           }
       }
   }
   ```
3. Register it in `shell.qml` if it needs to auto-load
4. Update `CLAUDE.md` key services table
5. Update `docs/src/content/docs/ai-agents/01-architecture.md` services table

## Adding a settings page

1. Create QML page in `modules/sysSettings/`:
   ```qml
   import QtQuick
   import QtQuick.Controls
   import "../common" as Common

   Column {
       spacing: 12
       // Your settings UI here
   }
   ```
2. Register in `SystemSettings.qml` category list
3. Use `Config.save()` after modifying any config property:
   ```qml
   onCheckedChanged: {
       Config.options.yourFeature.enabled = checked
       Config.save()
   }
   ```

## Adding a custom package

1. Edit `dots/custom/packages.sh`
2. Add the package name (one per line, no `#` prefix for active packages):
   ```bash
   custom_packages() {
       your-package-name
   }
   ```
3. Run `./setup install` to apply

## Syncing with upstream

1. Fetch upstream changes:
   ```bash
   git fetch upstream
   ```
2. Merge:
   ```bash
   git merge upstream/main
   ```
3. Resolve any conflicts:
   - **modify/delete conflicts:** Accept upstream deletion, port your changes to new format
   - **content conflicts:** Merge both sides, keeping user customizations
4. Test:
   ```bash
   qs -c ii  # Verify Quickshell loads
   hyprctl reload  # Verify Hyprland config
   ```
5. Update documentation:
   - Add entry to `dots/custom/EDITED.md` if you made changes during resolution
   - Update `docs/` guide pages if merge introduced new features or changed behavior

## Testing changes

### Quickshell
```bash
# Kill and restart
pkill qs; qs -c ii

# Test single component
qs -p ~/.config/quickshell/ii/settings.qml
qs -p ~/.config/quickshell/ii/SystemSettings.qml
```

### Hyprland
```bash
# Reload config (preserves session)
hyprctl reload

# Check for config errors
hyprctl instances
```

### Full install test
```bash
# Use a test user or VM
./setup install
```

## Code style checklist

Before committing, verify:

- [ ] QML uses spaces (not tabs)
- [ ] Properties and children are logically grouped with spacing
- [ ] Operators have spaces: `if (condition) { ... }`
- [ ] Early returns preferred over deep nesting
- [ ] Dynamic components use `Loader` with positioning on the Loader
- [ ] Config changes call `Config.save()`
- [ ] No significant resource usage for minor features
- [ ] Fancy features have a config toggle (disabled by default)
