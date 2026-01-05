{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Import the unstable channel specifically for dev tools
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };
in
{
  # IMPORTS.
  imports = [
    ./vscode.nix
    ./vscodium.nix
  ];
  # 1. Define the Option
  options = {
    modules.dev.tools = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable development tools (VS Code, direnv, nix-ld)";
      };
    };
  };

  # 2. The Configuration
  config = lib.mkIf config.modules.dev.tools.enable {

    # 1. Development Tools Manifest
    environment.systemPackages = [
      # --- Tools from STABLE ---
      pkgs.direnv
      pkgs.nix-direnv
      pkgs.zed-editor
      pkgs.devpod
      pkgs.devpod-desktop

      # --- Tools from UNSTABLE ---
      unstable.nixd
      unstable.nil
      unstable.nix-ld
    ];

    # 2. Direnv Configuration
    programs.bash.interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';

    # 3. nix-ld Configuration
    programs.nix-ld.enable = true;

    # 4. Storage Optimizations
    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };
  };
}
