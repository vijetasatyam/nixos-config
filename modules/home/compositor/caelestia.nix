{
  pkgs,
  inputs,
  caelestia-pkg,
  ...
}: {
  home.packages = with pkgs; [
    # 1. Patched Caelestia package (ScreenState fallbacks for Niri + compiled Qt/C++ plugins)
    caelestia-pkg

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

  # Matugen dynamic theming hook
  # Uses '--source-color-index 0' so it generates valid non-interactive JSON without ANSI prompt artifacts
  home.activation.matugen = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    WALLPAPER="/home/alice/Pictures/catppuccin-wallpaper.png"
    SCHEME_DIR="/home/alice/.local/state/caelestia"
    if [ -f "$WALLPAPER" ]; then
      mkdir -p "$SCHEME_DIR"
      ${pkgs.matugen}/bin/matugen image "$WALLPAPER" -m dark --source-color-index 0 --json hex > "$SCHEME_DIR/scheme.json" 2>/dev/null || true
    fi
  '';
}
