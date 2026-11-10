# Wallpaper rotation tests

Run from the repository root with Qt Quick Test installed:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/wallpaper-rotation
```

The tests instantiate the real `WallpaperRotation.qml` component. Fixtures exercise
file filtering, empty folders, missing folders, absolute paths, file URLs and avoiding the current image.
The scheduling tests verify startup behavior, interval changes, pause/resume,
busy handling and unloading through a `Loader`.

Timers are accelerated after checking their configured intervals. These tests do
not wait for real minutes, run `switchwall.sh`, or change desktop themes.
Image fixtures are used for file discovery, not image decoding.

The terminal-only tests disable automatic scheduling and explicitly request a switch.
Requests made before directory loading or during an active switch are deferred and coalesced.

Test the actual Hyprland keybindings without executing applications:

```sh
lua tests/wallpaper-rotation/terminal-keybinds.lua
```

The Lua test loads the real keybindings with mocked APIs. It checks that Super+Enter
launches the configured terminal before notifying Quickshell, while Ctrl+Alt+T
keeps only its original terminal action.
