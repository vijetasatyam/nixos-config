{
  config,
  pkgs,
  lib,
  pkgs-unstable,
  ...
}: {
  # 1. Imports (The Hub)
  # Importing these here makes this file the "Parent" of the dev suite.
  # You can remove these imports from home.nix if you want to keep home.nix clean.
  imports = [
    ./vscode.nix
    ./vscodium.nix
    ./neovim.nix
  ];

  # 2. Define the Option
  options = {
    modules.dev.tools = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable development tools (VS Code, direnv, zed, etc)";
      };
    };
  };

  # 3. The Configuration (Only runs if enable = true)
  config = lib.mkIf config.modules.dev.tools.enable {
    # Packages
    home.packages = [
      # Stable
      pkgs.zed-editor
      pkgs.devpod
      pkgs.devpod-desktop

      # Unstable
      pkgs-unstable.nixd
      pkgs-unstable.nil
    ];

    # Direnv (Home Manager Native Module)
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
    };
  };
}
