# Install scripts using Nix to achieve cross-distros
- This directory is currently WIP.
- See also [Install scripts | illogical-impulse](https://ii.clsty.link/en/dev/inst-script/)
- See also [#1061](https://github.com/end-4/dots-hyprland/issues/1061)

**NOTE: The sdist/nix is not for NixOS but every distro, using Nix and home-manager.**

## plan
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

## Attentions
### PAM
On non-NixOS distros, programs using PAM (typically screen locker) will not work if installed via Nix, so user has to use their own distro's package for the screen lock.

- One problem is that Debian(-based) distros use modified version of PAM which supports `@include` directive in `/etc/pam.d` config files but the PAM from Nix does not support it, see [this comment](https://github.com/NixOS/nixpkgs/issues/128523#issuecomment-1086106614).
- Another problem is the location of a suid helper binary that is necessary, see [this comment](https://github.com/end-4/dots-hyprland/issues/1061#issuecomment-3403195230).

The problem could be solved by using the system-provided libpam instead.

See also https://github.com/caelestia-dots/shell/issues/668

### NixGL
On non-NixOS distros, packages installed via home-manager have problem accessing GPU, especially Hyprland because it requires GPU acceleration to launch. `nixGL` should be used to address the problem. Example code in `home.nix`:
```
{ config, lib, pkgs, nixgl, ... }:
{
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  
  # other lines not showed here ...

  home = {
    packages = with pkgs; [
      cowsay           # normal packages that does not need nixGL
      lolcat
      # other lines not showed here ...
    ]
    ++ [
    (config.lib.nixGL.wrap pkgs.firefox-bin)
    (config.lib.nixGL.wrap pkgs.hyprland)
    # other lines not showed here ...
    ];
    # other lines not showed here ...
  };
}
```

And in `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    nixgl.url = "github:nix-community/nixGL";
  };
  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
      };
    in {
      homeConfigurations = {
        mydot = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixgl; };
          modules = [ ./home.nix ];
          };
        };
      };
}
```
