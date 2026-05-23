# Install scripts for Gentoo

Note:
- The scripts here are **not** meant to be executed directly.
- This folder should reflect the equivalents of `/sdata/dist-arch/` but under Gentoo.
  - **When `/sdata/dist-arch/` is newer than this folder, an update on this folder is very likely needed.**
  - Useful link: [Commit history on sdata/dist-arch/](https://github.com/end-4/dots-hyprland/commits/main/sdata/dist-arch)
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)

## Contributors
- Author: [jwihardi](https://github.com/jwihardi)

## install-deps.sh
1. Enables localrepo and guru overlays if not already enabled.
2. Copies _keywords_ to _keywords-user_ and appends the correct unmask keywords for the user's architecture (adm64, arm64, and x86 are supported).
3. _keywords-user_ and _useflags_ are copies over into the proper portage directories. Quickshell also uses a live ebuild.
4. Syncs, updates, and depcleans @world.
5. Copies over the custom live ebuilds (hyprgraphics, hyprland-qt-support, hyprland-qtutils, hyprlang, hyprwayland-scanner) into localrepo and digests them.
6. Loops through all illogical-impulse ebuilds to digest and emerge them.

## Recommended use flags (useflags)
- **The recommended useflags are not required, this is a more out of the box experience with these**
- Pipewire is used, alsa and pulseaudio are disabled (enabling them won't hurt).
- Init system is not assumed or considered so disabling systemd should be done in make.conf, same with session managers (elogind is recommended).

## Making the dot-files work
- elogind is expected to be installed and run as a service on OpenRC to set `XDG_RUNTIME_DIR`
  - NOT recommended: seatd will require more manual setup
- pipewire, pipewire-pulse, and wireplumber must be started after a dbus-session is created and before Hyprland is launched.

If you want to start after logging into tty1 you can do something like this.
```fish
if status --is-interactive; and [ (tty) = "/dev/tty1" ]
    # Start DBus session if not running
    if not set -q DBUS_SESSION_BUS_ADDRESS
        dbus-launch --sh-syntax | sed 's/^/set -gx /; s/=/ /' | source
    end

    # Start PipeWire if not running
    pgrep -x pipewire >/dev/null; or pipewire &
    pgrep -x pipewire-pulse >/dev/null; or pipewire-pulse &
    pgrep -x wireplumber >/dev/null; or wireplumber &

    # Launch Hyprland with DBus session
    exec Hyprland
end
```

## Known Issues
- If Hyprland is just blank, rebuild Quickshell (`emerge -q gui-apps/quickshell`)
- `Hyprland: error while loading shared libraries: libhyprgraphics.so.0: cannot open shared object file: No such file or directory`
  - The Hyprland live ebuild sometimes has linkage issues, deleting _Hyprland_ and _hyprland_ from `/usr/bin/` and then re-emerging usually fixes this.
- When emerging Hyprland if you get an issue relating to `undefined reference to ``Hyprutils::Math::Vector2D::˜Vector2D()`` `
  - Clear the cache folder (`rm -fr /var/tmp/portage/gui-wm/hyprland*`) then try again
