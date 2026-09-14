# Install scripts for Gentoo

Note:
- The scripts here are **not** meant to be executed directly.
- This folder should reflect the equivalents of `/sdata/dist-arch/` but under Gentoo.
  - **When `/sdata/dist-arch/` is newer than this folder, an update on this folder is very likely needed.**
  - Useful link: [Commit history on sdata/dist-arch/](https://github.com/end-4/dots-hyprland/commits/main/sdata/dist-arch)
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)

## Contributors

- Author: [jwihardi](https://github.com/jwihardi)

This directory contains the Gentoo dependency definitions used by the main
illogical-impulse installer. It mirrors the package groups maintained in
[`sdata/dist-arch`](../dist-arch/) with Gentoo metapackages and a local Portage
overlay.

The complete package set is currently intended for **amd64**. Some individual
ebuilds also carry arm64 or x86 keywords, but not every illogical-impulse
metapackage supports those architectures yet.

## How installation works

The dependency installer:

1. Installs `eselect-repository`, `rsync`, and `smart-live-rebuild`.
2. Enables the GURU and hyproverlay repositories when necessary.
3. Copies [`overlay/`](overlay/) to `/var/db/repos/ii-dots` and installs its
   repository configuration.
4. Generates `/etc/portage/package.accept_keywords/illogical-impulse` for the
   current architecture from [`keywords`](keywords).
5. Installs [`useflags`](useflags) and [`additional-useflags`](additional-useflags)
   as `/etc/portage/package.use/illogical-impulse`.
6. Syncs configured repositories, updates `@world`, and rebuilds
   installed live packages.
7. Emerges every metapackage listed in [`metapkgs.sh`](metapkgs.sh).

Note: The installer also ensures Python 3.12 is installed.

The `ii-dots` repository has `auto-sync = no`. A normal `emerge --sync` does
not update it; rerun the illogical-impulse installer to copy the current
overlay into Portage.

## Repository contents

| Path | Purpose |
| --- | --- |
| [`overlay/`](overlay/) | Local ebuild repository containing the II metapackages and packages not provided in the required form elsewhere. |
| [`ii-dots.conf`](ii-dots.conf) | Portage repository configuration installed under `/etc/portage/repos.conf`. |
| [`keywords`](keywords) | Packages that must accept testing or unkeyworded ebuilds. The installer appends the current testing keyword. |
| [`useflags`](useflags) | Direct feature requirements for the II package set. |
| [`additional-useflags`](additional-useflags) | Transitive feature requirements appended to the same Portage package.use file. |
| [`metapkgs.sh`](metapkgs.sh) | Package groups installed and removed by the dependency scripts. |

MicroTeX and Material Symbols use live ebuilds. Quickshell keeps the `-git`
package name for compatibility but is pinned to a tested upstream commit.
Versioned theme and font ebuilds may also use pinned commits as their source.

## System requirements

Choose either `elogind` or `systemd` globally so all installed packages use
the same session manager. On OpenRC, `elogind` is recommended and
must be running so the user session receives `XDG_RUNTIME_DIR`.

## Uninstalling

The uninstall path removes the II metapackages, local overlay, repository
configuration, keyword file, and USE file. It does not automatically remove
dependencies that have become unused; review `emerge --depclean --pretend`
before deciding whether to depclean them.
