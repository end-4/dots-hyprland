# Install scripts for Fedora Linux

- Synchronize all dependencies in arch.
- It has been tested on Fedora 43 (KDE Plasma Desktop Edition) on the x86_64 platform.
- If you have any questions, please submit them to the discussions section.

## About `hyprland-qtutils` and `hyprland-qt-support`

The hyprland-qt-support's GitHub repository requires Qt 6.6 or higher, which I think makes DNF's requirement of Qt 6.9 too strict; it should also support Qt 6.10.

According to @clsty 's discussion `hyprland-qtutils` and `hyprland-qt-support` have been removed in dist-arch recently.
https://github.com/end-4/dots-hyprland/pull/2393#discussion_r2503594243
However, if this package is not installed, a yellow warning⚠️ will appear every time you log in to Hyprland.  
so for now, these two packages will be kept by default.
Of course, you can choose to skip installing these two packages during the installation process, or uninstall them after installation.

# Usage
- `git clone --recurse-submodules https://github.com/end-4/dots-hyprland ~/.cache/dots-hyprland`
- `cd ~/.cache/dots-hyprland`
- `./setup install`

# After installation
- Fix the issue of the right column crashing when clicking the `Details` button in Wi-Fi mode. Edit this file: ~/.config/illogical-impulse/config.json
```
@@ 44,3 44,3 @@
-  "apps": {
-    "bluetooth": "kcmshell6 kcm_bluetooth",
-    "network": "kitty -1 fish -c nmtui",
+  "apps": {
+    "bluetooth": "kcmshell6 kcm_bluetooth",
+    "network": "plasmawindowed org.kde.plasma.networkmanagement",
```
