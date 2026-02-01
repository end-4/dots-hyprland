# Install scripts using Nix to achieve cross-distros
- This directory is currently WIP.
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)
- See also [#1061](https://github.com/end-4/dots-hyprland/issues/1061)

**NOTE: The `dist-nix` is not for NixOS but every distro, using Nix and home-manager.**

As we all know Nix and Home-manager has two major functionalities:
- Handling dependencies (i.e. package installation)
- Handling dotfiles

They are discussed in following sections.

# Handling dependencies
## Status
Partially works. See [Discussion #2382](https://github.com/end-4/dots-hyprland/discussions/2382).
## plan
Note that this script must be idempotent.

TODO:
- [ ] Fix all TODOs inside `dist-nix`. ([search online](https://github.com/search?q=repo%3Aend-4%2Fdots-hyprland+path%3A%2F%5Esdata%5C%2Fdist-nix%5C%2F%2F+TODO&type=code))
- [ ] Since Nix uses a large number of inodes, need to warn user if inode-limited filesystem (typically ext4) is used.
- [ ] Deal with error when running `systemctl --user enable ydotool --now`:
  ```plain
  Failed to connect to user scope bus via local transport: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)
  ```
- [ ] Handle problem that `pkill qs` and `pkill hyprland` does not work (should be `.quickshell-wra` and `.Hyprland-wrapp` when installed via Nix).

## Attentions
### PAM
On non-NixOS distros, programs using PAM (typically screen locker) will not work if installed via Nix, so user has to use their own distro's package for the screen lock.

- One problem is that Debian(-based) distros use modified version of PAM which supports `@include` directive in `/etc/pam.d` config files but the PAM from Nix does not support it, see [this comment](https://github.com/NixOS/nixpkgs/issues/128523#issuecomment-1086106614).
- Another problem is the location of a suid helper binary that is necessary, see [this comment](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3403195230).

As [commented](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3403195230) by @Cu3PO42 , both the problem could be solved by using the system-provided libpam instead.

See also [caelestia-dots/shell#668](https://github.com/caelestia-dots/shell/issues/668).

### GPU
On non-NixOS distros, packages installed via home-manager have problem accessing GPU, especially Hyprland because it requires GPU acceleration to launch.

~~`nixGL` should be used to address the problem.~~

Since home-manager 25.11, for non-NixOS just set the following:
```nix
targets.genericLinux.enable = true;
```
Then during building, home-manager will show a message to tell you running a command manually to configure GPU, like:
```bash
sudo /nix/store/<HASH>-non-nixos-gpu/bin/non-nixos-gpu-setup
```
It runs a bash script with following content:
```
#!/nix/store/<HASH>-bash-<VERSION>/bin/bash

set -e

# Install the systemd service file and ensure that the store path won't be
# garbage-collected as long as it's installed.
unit_path=/etc/systemd/system/non-nixos-gpu.service
ln -sf /nix/store/<HASH>-non-nixos-gpu/resources/non-nixos-gpu.service "$unit_path"
ln -sf "$unit_path" "/nix/var/nix"/gcroots/non-nixos-gpu.service

systemctl daemon-reload
systemctl enable non-nixos-gpu.service
systemctl restart non-nixos-gpu.service
```
_Note: it uses `systemctl`, maybe won't work for OpenRC..._

See [gpu-non-nixos](https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos).

# Handling dot files
## Status
Paused, until some suitable method has been confirmed to meet the requirements below.
## Requirements
About handling the dotfiles, i.e. `dots/`, if we are doing this using Nix then the following requirements must be fulfilled.

**1. Allow modifications over the existing dotfiles.**

Current state of `./setup install`:
- After finishing running `./setup install`, users can modify any dotfiles in a traditional way, and if they run `./setup install` again to update then they need to skip the steps which overwrite the targets that they have modified and later sync the upgrade manually for such targets by themselves.
  - For Hyprland, specially we have a `custom` folder along with `~/.config/hypr/hyprland.conf` which will only get overwritten the first time but not the later times running `./setup install`.
- This works but is not elegant. An experimental solution is using yaml config to store the selected behavior for each target, see [#2137](https://github.com/end-4/dots-hyprland/issues/2137).

If we use Nix to handle dotfiles, then it must be at least better than the current state described above, mainly in terms of convenience and automation.

**2. Allow choosing targets.**

This is similar to the above. For example user may want to use their own `~/.config/foot` instead of the files under `dots/.config/foot` entirely.

**3. Easy developing dotfiles or at least not worse than current state.**

About the current state:
- @clsty: "If I were the one who develops the dotfiles, I will make changes to the local Git repo `dots-hyprland` and rerun `./setup install-files -f` to apply the changes to observe the outcome."
- @end-4 (who develops the dots; see [comment](https://github.com/end-4/dots-hyprland/pull/2278#issuecomment-3454929577)): "I modify my local copy of stuff, copy the relevant parts over, optionally selectively pick changes then commit. It's.... the most obvious way but I guess not necessarily the cleanest"

If we use Nix to handle dotfiles, then it must be at least better than the current state described above, mainly in terms of convenience and automation.

**4. Others**

Find out a good method to avoid what @end-4 [mentioned](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-2954725029):

> About home-manager, from my limited understanding of and experience with it, any change to the config files require a rebuild right? If this is indeed the case, switching entirely to this is not okay. Having to wait 20 seconds for each change is absurd.

Some information may help, e.g. @darsh032 [commented](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3336839862):

> I mean thats not really needed you can use mkOutOfStoreSymlink or use hjem-impure to change the configs without rebuilding

And also the "hmrice" [mentioned](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3353345504) by @Markus328 , and the `flake.nix` (for quickshell only) [mentioned](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3354387126) by @darsh032 .
