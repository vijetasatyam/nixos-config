#/home/alice/nixos-config/flake/flake.nix
{
  description = "Alice's Modular Hybrid Config";

  inputs = {
    # 1. Stable Base
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # 2. Unstable Source
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # 3. Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 4. Quickshell
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # 5. iNiR (Native Niri Material Shell)
    inir = {
      url = "github:snowarch/inir";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # 6. DankMaterialShell (DMS) with git submodules enabled
    dms = {
      url = "git+https://github.com/AvengeMedia/DankMaterialShell?submodules=1";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    quickshell,
    inir,
    dms,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    shared-config = {
      allowUnfree = true;
    };

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = shared-config;
    };

    # Catppuccin Mocha Tokens
    theme = {
      name = "catppuccin-mocha";
      bg = "#1e1e2e";
      text = "#cdd6f4";
      accent = "#cba6f7";
      border = "#b4befe";
      surface = "#313244";
      active = "#89b4fa";
      urgent = "#f38ba8";
      success = "#a6e3a1";
      warning = "#f9e2af";
    };
  in {
    nixosConfigurations = {
      sage = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs pkgs-unstable theme;
        };

        modules = [
          ../hosts/sage/configuration.nix

          {nixpkgs.config = shared-config;}

          # System-level Niri enablement
          {
            programs.niri.enable = true;
          }

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";

            home-manager.extraSpecialArgs = {
              inherit inputs pkgs-unstable theme;
            };

            home-manager.users.alice = import ../modules/home/home.nix;
          }
        ];
      };
    };

    templates = {
      python = {
        path = ../devshells/python;
        description = "Python isolated development environment";
      };
      node = {
        path = ../devshells/node;
        description = "NodeJS isolated development environment";
      };
      rust = {
        path = ../devshells/rust;
        description = "Rust isolated development environment";
      };
    };
  };
}
