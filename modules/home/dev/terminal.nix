{ pkgs, pkgs-unstable, ... }:

{
  # 1. Install Terminal Packages
  home.packages = with pkgs; [
    # The Terminal itself (Unstable for latest features)
    pkgs-unstable.ghostty

    # Fonts required for icons (Nerd Fonts)
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # 2. Ghostty Configuration
  # Ghostty reads from ~/.config/ghostty/config
  xdg.configFile."ghostty/config".text = ''
    # --- Fonts ---
    font-family = "JetBrainsMono Nerd Font"
    font-size = 12

    # --- Theme ---
    # Ghostty has built-in support for Dracula
    theme = Dracula

    # --- Window UI ---
    window-decoration = false
    gtk-titlebar = false

    # --- Integration ---
    # Adjust this if you use bash instead of zsh
    shell-integration = zsh

    # --- Clipboard ---
    clipboard-read = allow
    clipboard-write = allow

    # --- Cursor ---
    cursor-style = block
    cursor-style-blink = false

    # --- Optimization ---
    # fast-scroll = true
  '';

  # Ensure fontconfig picks up the new fonts
  fonts.fontconfig.enable = true;
}
