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
              # 1. Fallback for ScreenState active monitor
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

              # 2. Disable border exclusion zones
              substituteInPlace $out/share/caelestia-shell/modules/drawers/Drawers.qml \
                --replace-fail '        Exclusions {' '        /* Exclusions {' \
                --replace-fail '        ContentWindow {' '        */ ContentWindow {'

              # 3. Eliminate the 50-100px dragMaskPadding dead-zone along all screen edges
              substituteInPlace $out/share/caelestia-shell/modules/drawers/Regions.qml \
                --replace-fail '    x: bar.clampedWidth + win.dragMaskPadding' '    x: bar.clampedWidth' \
                --replace-fail '    y: clampedThickness + win.dragMaskPadding' '    y: 0' \
                --replace-fail '    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2' '    width: win.width - bar.clampedWidth' \
                --replace-fail '    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2' '    height: win.height'

              # 4. Dynamically collapse outer border and negative margins on fullscreen
              substituteInPlace $out/share/caelestia-shell/modules/drawers/ContentWindow.qml \
                --replace-fail 'anchors.margins: -50' 'anchors.margins: root.hasFullscreen ? 0 : -50' \
                --replace-fail 'borderThickness: root.contentItem.Config.border.thickness' 'borderThickness: root.hasFullscreen ? 0 : root.contentItem.Config.border.thickness' \
                --replace-fail 'clampedThickness: root.contentItem.Config.border.clampedThickness' 'clampedThickness: root.hasFullscreen ? 0 : root.contentItem.Config.border.clampedThickness'
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
