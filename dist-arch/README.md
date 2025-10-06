# Install scripts for Arch Linux
## Old Dependency Installation Method
The old deps install method mainly involved `./scriptdata/dependencies.conf` (which has been removed now).

There was also a `checkdeps.sh`:
  - It checks the existence of pkgs listed in `./scriptdata/dependencies.conf`.
  - It somehow fixes [the problem caused by yay](https://github.com/end-4/dots-hyprland/discussions/204).

## Current Dependency Installation
Local PKGBUILDs under `./dist-arch/` are used to install dependencies.

The mechanism is introduced by [Makrennel](https://github.com/Makrennel) in [PR#570](https://github.com/end-4/dots-hyprland/pull/570).

Why is this awesome?
- It makes it possible to control version since some packages may involve breaking changes from time to time.
- It makes the dependency trackable for package manager, so that you always know why you have installed some package.
- As a result, it enables a workable `uninstall.sh` script.

The PKGBUILDs contains two forms of dependencies:
- Package name written in dependencies, like a "meta" package.
- Normal PKGBUILD content to build dependencies, e.g. AGS, which is often for version controlling.
