# flake.nix
{
  description = "illogical-impulse";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #hyprland = {
    #  url = "github:hyprwm/Hyprland";
    #};
    nixgl.url = "github:nix-community/nixGL";
    quickshell = {
      url = "github:quickshell-mirror/quickshell/db1777c20b936a86528c1095cbcb1ebd92801402";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      home_attrs = rec {
        username = import ./username.nix;
        homeDirectory = "/home/${username}";
        stateVersion = "25.05";
      };
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      homeConfigurations = {
        illogical_impulse = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixgl home_attrs; };
          modules = [ 
            ./home.nix
          ];
        };
      };
    };
}
