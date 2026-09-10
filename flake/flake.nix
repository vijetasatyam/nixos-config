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

    # 5. Caelestia Shell
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    quickshell,
    caelestia-shell,
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
      config = shared-config;
    };

    # Patch caelestia-shell to fall back to the primary screen under Niri
    caelestia-shell-patched = caelestia-shell.packages.${system}.default.overrideAttrs (oldAttrs: {
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
              # Fallback for forActive()
              substituteInPlace $out/share/caelestia-shell/services/ShellState.qml \
                --replace-fail '        return null;' '        return states.instances[0] ?? null;' \
                --replace-fail '    function componentsForActive(): Components {' \
                               '    function componentsForActive(): Components {
              const mon = Hypr.focusedMonitor;
              for (const c of components.instances)
                  if (Hypr.monitorFor(c.modelData) === mon)
                      return c;
              return components.instances[0] ?? null;
          }
          function _unusedComponents(): void {'
        '';
    });

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
          caelestia-pkg = caelestia-shell-patched;
        };

        modules = [
          ../hosts/sage/configuration.nix

          {nixpkgs.config = shared-config;}

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";

            home-manager.extraSpecialArgs = {
              inherit inputs pkgs-unstable theme;
              caelestia-pkg = caelestia-shell-patched;
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
