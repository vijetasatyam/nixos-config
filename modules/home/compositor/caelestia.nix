{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # 1. Use the pre-compiled Caelestia package (bundles Caelestia.Config and Qt plugins)
    inputs.caelestia-shell.packages.${pkgs.system}.default

    # 2. Dynamic Material Design 3 Palette Generator
    matugen

    # 3. System integration utilities
    wireplumber
    brightnessctl
    playerctl
    networkmanager
    bluez
    socat
    jq
    libnotify

    # 4. Typography & Icons
    material-symbols
    rubik
    nerd-fonts.jetbrains-mono
  ];

  # Symlink Caelestia's QML code & assets
  xdg.configFile."quickshell".source = inputs.caelestia-shell.outPath;

  # Matugen dynamic theming hook (safe fallback with .png and || true)
  home.activation.matugen = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    WALLPAPER="/home/alice/Pictures/catppuccin-wallpaper.png"
    if [ -f "$WALLPAPER" ]; then
      ${pkgs.matugen}/bin/matugen image "$WALLPAPER" -m dark || true
    fi
  '';
}
