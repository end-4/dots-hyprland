# Home Assistant Integration (Quickshell)

This branch adds a HomeKit-style Home Assistant panel to the top bar.

## What it does

- Adds a `home` icon in the bar.
- Opens a Home panel with grouped devices:
  - Cameras (top row)
  - Security & Access
  - Lighting
  - Climate & Appliances
- Supports:
  - Toggle actions for lights/switches/locks/covers/climate
  - Brightness slider for dimmable devices
  - Camera click opens PiP live stream (via `mpv`), with fallback

## Privacy-safe configuration

Personal setup is now expected in an external file outside the repo:

- Default path: `~/.config/illogical-impulse/homeassistant.json`
- Optional override in settings:
  - `Services -> Home Assistant -> External config path`

This keeps personal entity names and tokens out of git-tracked config.

## External config format

```json
{
  "url": "https://your-home.ui.nabu.casa",
  "token": "YOUR_LONG_LIVED_ACCESS_TOKEN",
  "fetchInterval": 15,

  "cameras": ["camera.front_door"],
  "lights": ["light.living_room"],
  "locks": ["lock.front_door"],
  "covers": ["cover.garage"],
  "climate": ["climate.main"],
  "appliances": ["switch.coffee_maker"]
}
```

`fetchInterval` is in minutes.

## Notes

- If `url` omits scheme, `https://` is auto-added.
- If `mpv` is installed, camera tiles open an always-on-top PiP window.
- If external config is missing, shell settings values are used as fallback.
