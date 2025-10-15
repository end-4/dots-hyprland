# Install scripts using Nix to achieve cross-distros
- This directory is currently WIP.
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)
- See also [#1061](https://github.com/end-4/dots-hyprland/issues/1061)

NOTE: The sdist/nix is not for NixOS but every distro, using Nix and home-manager.

TODO:
Write a proper `flake.nix` and optionally `home.nix` and other files under `./sdist/nix/iiqs-hm/` to install all dependencies that `./sdist/arch/install-deps.sh` does. (**excluding** the screenlock)

TODO:
In this script, implement the process below:
1. Warning user about "this script is only experimental and must only use it at your own risks.", and prompt `y/N` (default N) before proceeding.
2. If nix not installed:
   1. install nix via [NixOS/experimental-nix-installer](https://github.com/NixOS/experimental-nix-installer)
   2. Enable nix for shell 
      - Update: Skip this step cuz the nix-installer will handle it automatically e.g. in `/etc/zsh/zshrc`.
   3. Ensure the experimental feature, Nix Flake, is enabled.
3. cd to `iiqs-hm` and use something like `home-manager switch --flake .#iiqs` to install the dependencies.
4. Install screen lock using system package manager of the current distro.

Note that this script must be idempotent.

TODO:
Write guide for people already use nix, so they can manually grab things from this repo to their own Nix/home-manager configurations to install the dependencies.
