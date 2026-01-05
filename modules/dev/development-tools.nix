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

# { config, pkgs, ... }:

# let
#   # Import the unstable channel specifically for dev tools
#   unstable = import <unstable> {
#     config = config.nixpkgs.config;
#   };
# in
# {
#   # 1. Development Tools Manifest
#   environment.systemPackages = [
#     # --- Tools from STABLE ---
#     pkgs.direnv # Automatically loads/unloads project environments on 'cd'
#     pkgs.nix-direnv # Fast Nix integration for direnv (prevents slow re-evaluations)
#     pkgs.zed-editor # text editor like vscode but turbocharger on it.

#     # --- Tools from UNSTABLE ---
#     unstable.vscode
#     unstable.nixd # Nix Language Server (provides autocomplete/error checking for .nix files)
#     unstable.nil # An alternative Nix Language Server (often faster/more modern than nixd)
#     unstable.nix-ld # The loader that allows unpatched Linux binaries to run on NixOS
#   ];

#   # 2. Direnv Configuration
#   # This "hooks" direnv into your Bash shell automatically
#   programs.bash.interactiveShellInit = ''
#     eval "$(direnv hook bash)"
#   '';

#   # 3. nix-ld Configuration
#   # Vital for VS Code: allows running non-Nix unpatched binaries
#   programs.nix-ld.enable = true;

#   # 4. Storage Optimizations
#   # Prevents Nix from garbage-collecting your development environments
#   nix.settings = {
#     keep-outputs = true;
#     keep-derivations = true;
#   };

# }
