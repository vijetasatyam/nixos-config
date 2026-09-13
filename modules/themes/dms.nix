# /home/alice/nixos-config/modules/themes/dms.nix
{
  pkgs,
  inputs,
  ...
}: {
  programs.dms-shell = {
    enable = true;

    # Optional: point to git quickshell if desired, or omit to use native package
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    systemd = {
      enable = true;           # Generates and starts dms.service on login
      restartIfChanged = true; # Restarts dms when the package updates
    };

    # Core features & widgets
    enableSystemMonitoring = true;   # dgop backend
    enableVPN = false;               # Set to true if managing VPN via widget
    enableDynamicTheming = true;     # Matugen theming
    enableAudioWavelength = true;    # Cava audio visualizer
    enableCalendarEvents = true;     # Khal calendar events
  };
}
