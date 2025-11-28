# flake.nix
{
  description = "illogical-impulse";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    #nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      #url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nixgl.url = "github:nix-community/nixGL";
    quickshell = {
      url = "github:quickshell-mirror/quickshell/db1777c20b936a86528c1095cbcb1ebd92801402";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, 
  #nixgl,
  quickshell, ... }:
    let
      home_attrs = rec {
        username = import ./username.nix;
        homeDirectory = "/home/${username}";
        # Do not edit stateVersion value, see https://github.com/nix-community/home-manager/issues/5794
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
          extraSpecialArgs = { inherit home_attrs 
          #nixgl
          quickshell; };
          modules = [ 
            ./home.nix
          ];
        };
      };
    };
}
