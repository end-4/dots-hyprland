# Install scripts for Fedora Linux

Note:
- The scripts here are **not** meant to be executed directly.
- This folder should reflect the equivalents of `/sdata/dist-arch/` but under Fedora.
  - **When `/sdata/dist-arch/` is newer than this folder, an update on this folder is very likely needed.**
  - Useful link: [Commit history on sdata/dist-arch/](https://github.com/end-4/dots-hyprland/commits/main/sdata/dist-arch)
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)

## Contributors
- Author: [ririko6z](https://github.com/ririko6z)

## Tested
- It has been tested on Fedora 43 (KDE Plasma Desktop Edition) on the `x86_64` platform.

## Post installation
- Fix the issue of the right column crashing when clicking the `Details` button in Wi-Fi mode. Edit this file: `~/.config/illogical-impulse/config.json`
```diff
@@ 44,3 44,3 @@
-  "apps": {
-    "bluetooth": "kcmshell6 kcm_bluetooth",
-    "network": "kitty -1 fish -c nmtui",
+  "apps": {
+    "bluetooth": "kcmshell6 kcm_bluetooth",
+    "network": "plasmawindowed org.kde.plasma.networkmanagement",
```

