# End-4 dot-files for Gentoo


## install-deps.sh
1. Enables localrepo and guru overlays if not already enabled.
2. Copies _keywords_ to _keywords-user_ and appends the correct unmask keywords for the user's architecture (adm64, arm64, and x86 are supported).
3. _keywords-user_ and _useflags_ are copies over into the proper portage directories.
4. Syncs, updates, and depcleans @world.
5. Copies over the custom live ebuilds (hyprgraphics, hyprland-qt-support, hyprland-qtutils, hyprlang, hyprwayland-scanner) into localrepo and digests them.
6. Loops through all illogical-impulse ebuilds to digest and emerge them.

## install-setup.sh
1. Creates the _i2c_ group since Gentoo doesn't have this by default, then adds the user to it.
2. Enables _bluetooth_ and _ydotool_ services (systemd or openrc)
3. _icons_, _konsole_, _hypr_, and _quickshell_ are are chowned to user since they're emerge in as root by default.
4. gsettings and kwriteconfig6 are set (same as dist-arch).

## Recommended use flaags (useflags)
- Pipewire is used, alsa and pulseaudio are disabled (enabling them won't hurt).
- Init system is not assumed or considered so disabling systemd should be done in make.conf, same with session managers (elogind is recommended).

## Making the dot-files work
- pipewire, pipewire-pulse, and wireplumber must be started after a dbus-session is created and before Hyprland is launched.
