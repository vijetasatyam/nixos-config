{
  pkgs,
  inputs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    # Quickshell from Flake
    inputs.quickshell.packages.${pkgs.system}.default

    # Material You dynamic palette generator
    matugen

    # Shell dependencies
    wireplumber
    brightnessctl
    playerctl
    networkmanager
    bluez
    socat
    jq
    libnotify

    # Typography & Icons required by Caelestia
    material-symbols
    rubik
    nerd-fonts.jetbrains-mono
  ];

  # Symlink Caelestia upstream QML files into ~/.config/quickshell
  xdg.configFile."quickshell".source = inputs.caelestia-shell.outPath;

  # Initialize Matugen palette from your Catppuccin wallpaper
  home.activation.matugen = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    WALLPAPER="/home/alice/Pictures/catppuccin-wallpaper.png"
    if [ -f "$WALLPAPER" ]; then
      ${pkgs.matugen}/bin/matugen image "$WALLPAPER" -m dark || true
    fi
  '';
}
