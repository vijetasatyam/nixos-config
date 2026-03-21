{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.modules.core.flatpak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Flatpak support and Flathub repository";
    };
  };

  config = lib.mkIf config.modules.core.flatpak.enable {
    # 1. Enable the Flatpak Service
    services.flatpak.enable = true;

    # 2. Fix for Fonts and Icons
    # This ensures Flatpak apps can see your system fonts/icons
    fonts.fontDir.enable = true;

    # 3. Automatically add Flathub repository on system activation
    # This script runs every time you rebuild to ensure Flathub is ready
    system.activationScripts.flathub = {
      text = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
