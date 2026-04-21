## Waffle

A recreation of Windoes. It's WIP!

- If you install illogical-impulse fully, you can press Super+Alt+W to switch to this style.
- If you're just copying the Quickshell config, run the config as usual (`qs -c ii`) then run `qs -c ii ipc call panelFamily cycle`

## From EWW version to Quickshell

Just a reflection, in case anyone's interested. My blog is probably a better place for this, but it does not exist. Besides, this is going to change as I do more stuff. Currently there's just the bar.

### Improvements

- QtQuick's `Button` has the `{top/bottom/left/right}Inset` properties, so we can have clickable regions expanding beyond the button background for free. With EWW it was annoying to wrap the button content with an `eventbox` that has some padding, then somehow use CSS selectors to make sure hovering effects work. I have to admit, (a large) part of that annoyance was with how bad my copy-pasting coding practice was at the time, but still...

- Fancy effects: Gtk3 CSS does not support transformations. In QtQuick we can smack `rotation` and `scale` almost everywhere, so it's simple to make bouncy icons and rotating chevrons

- Quickshell provides a system tray service (EWW does now but didn't at the time I created the EWW Windoes version), so now there's no Waybar needed for the tray.

- QtQuick has `Loader`s, so we can have this live-switchable from the main style without killing the widget system, moving styles to the correct folder, and relaunching.

- This time my computer is powerful enough to run a VM, so I don't have to occasionally reboot to take quick screenshots for reference. I try to make everything pixel-perfect so this is necessary. Speaking about pixel-perfectness, in the EWW version I hardcoded sizes, but this time I'm still doing that (lol), BUT that's normal and not a problem because Qt has the `QT_SCALE_FACTOR` env var for scaling. (Please feel free to prove me wrong in saying Gtk3 doesn't have that magic)

### Challenges

- Qt is not Gtk and definitely not React
  - We don't get directional border on QtQuick `Rectangle`s like in CSS. I was able to get around this with manual drawing, but it was a bit more work

- Fluent Icons is difficult to use, compared to Material Symbols
  - No React, so no clean use via a library.
  - If we use the font, there's no proper, searchable **codepoint** cheatsheet like Nerd Fonts, and there's no ligatures
  - I resorted to downloading individual SVGs. Not that nice, but it's better than scanning the whole table of icons every time I want one. For this we have fluenticon.com and fluenticons.co, but icons are awkwardly named and there's no alias. Why is the reload/refresh icon called "arrow-sync"? Well, the name is not misleading, but arguably reload/refresh are more common actions. From Fluent Design's [page on Iconography](https://fluent2.microsoft.design/iconography):

  > Fluent system icons are literal metaphors and are named for the shape or object they represent, not the functionality they provide

  "sync" is functionality.

