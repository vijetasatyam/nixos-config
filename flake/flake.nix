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
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    quickshell,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # 1. Define a shared config block
    shared-config = {
      allowUnfree = true;
    };

    # 2. Apply it to the Unstable instance
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = shared-config; # Centralized here
    };

    # NEW: Abstract Themes into Variables (Catppuccin Mocha)
    theme = {
      name = "catppuccin-mocha";
      bg = "#1e1e2e"; # Base
      text = "#cdd6f4"; # Text
      accent = "#cba6f7"; # Mauve (Primary Accent)
      border = "#b4befe"; # Lavender
      surface = "#313244"; # Surface 1
      active = "#89b4fa"; # Blue
      urgent = "#f38ba8"; # Red
      success = "#a6e3a1"; # Green
      warning = "#f9e2af"; # Yellow
    };
  in {
    # NEW: Multi-Host Setup replacing the single nixosConfigurations.nixos
    nixosConfigurations = {
      # Host 1: Sage
      sage = nixpkgs.lib.nixosSystem {
        inherit system;

        # Inject 'theme' here for system-level modules
        specialArgs = {inherit inputs pkgs-unstable theme;};

        modules = [
          # Make sure to rename your 'hosts/nixos' folder to 'hosts/sage'
          ../hosts/sage/configuration.nix

          # 3. Apply it to the Stable instance via a module
          {nixpkgs.config = shared-config;} # Centralized here

          # Enable the official Mango NixOS module
          #mango.nixosModules.mango

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Inject 'theme' here for Home Manager modules
            home-manager.extraSpecialArgs = {inherit inputs pkgs-unstable theme;};

            home-manager.users.alice = import ../modules/home/home.nix;
          }
        ];
      };

      # Example Host 2: Laptop (For future use)
      # laptop = nixpkgs.lib.nixosSystem { ... };
    };

    # NEW: Dev Environments (Flake Templates)
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
