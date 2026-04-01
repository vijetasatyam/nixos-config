{
  pkgs,
  pkgs-unstable,
  ...
}: {
  # --- 1. Wayland Tools ---
  home.packages = with pkgs; [
    pkgs-unstable.mangowc

    wmenu # Native Wayland launcher
    swaybg # Wallpaper utility
    grim # Screenshot tool
    slurp # Region selector
    wl-clipboard # Clipboard sync

    # Fonts/Icons for aesthetics
    papirus-icon-theme
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.enable = true;

  # --- 2. Mango Configuration ---
  xdg.configFile."mango/config.conf".text = ''
    exec = ~/.config/mango/autostart.sh

    # Keybinds
    bind = super, Return, spawn, ghostty
    bind = super, d, spawn, wmenu -l 10
    bind = super, Q, killclient
    bind = super shift, R, reload

    # Navigation Features
    bind = super, 0, overview
    bind = super, V, layout, vertical_grid
    bind = super, S, spawn, ~/.config/mango/snip.sh

    # Aesthetics: Gaps and Borders
    gaps_inner = 10
    gaps_outer = 15
    border_width = 2
    border_color_active = #bd93f9
    border_color_inactive = #44475a
  '';

  # --- 3. Autostart & Scripts ---
  xdg.configFile."mango/autostart.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      swaybg -i ~/Pictures/wallpapers/wall4.jpeg &
      waybar &
    '';
  };

  xdg.configFile."mango/snip.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      grim -l 0 -g "$(slurp)" - | wl-copy
    '';
  };
}
