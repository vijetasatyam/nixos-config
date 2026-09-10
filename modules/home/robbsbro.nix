{
  pkgs,
  inputs,
  ...
}: {
  # 1. Install Robbsbro69's specific dependencies
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.system}.default
    pywal # Generates live color palettes
    cava # Audio visualizer used in their Quickshell music panel
    kitty # Their terminal of choice
    awww # Or keep swaybg if you prefer
    pamixer
    playerctl
    brightnessctl
  ];

  # 2. Map their dotfiles into your ~/.config directory
  # This tricks their Quickshell setup into thinking it's running natively
  xdg.configFile = {
    "quickshell".source = ./robbs-dots/quickshell;
    "cava".source = ./robbs-dots/cava;
    "kitty".source = ./robbs-dots/kitty;
  };

  # 3. Pywal initial setup script (runs on login)
  home.activation.pywal = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Generate a default colorscheme so Quickshell doesn't crash on first boot
    ${pkgs.pywal}/bin/wal -i /home/alice/Pictures/catppuccin-wallpaper.jpg -n -q
  '';
}
