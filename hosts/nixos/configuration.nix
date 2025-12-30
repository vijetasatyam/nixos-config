# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  # config,
  # pkgs,
  # lib,
  ...
}:

{
  # Imports.

  imports = [
    # --- Machine Specific ---
    ./hardware-configuration.nix

    # --- Core Modules ---
    ../../modules/core/system.nix
    ../../modules/core/networking.nix
    ../../modules/core/services.nix
    ../../modules/core/users.nix
    ../../modules/core/aliases.nix
    ../../modules/core/flathub.nix

    # --- Development Modules ---
    ../../modules/dev/development-tools.nix
    ../../modules/dev/git-config.nix
    ../../modules/dev/virtual-machines.nix

    # --- Application Modules ---
    ../../modules/apps/env-packages.nix
    ../../modules/apps/unstable-packages.nix
  ];

  # Channels.

  system.stateVersion = "25.11";

}
