{
  #config,
  pkgs,
  #pkgs-unstable,
  ...
}: {
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  # Import User Configs`
  imports = [
    ./dev/development-tools.nix
    ./dev/git-config.nix
    ./dev/terminal.nix
    ./compositor/niri.nix
    # ./compositor/waybar.nix
    # ./compositor/swaync.nix
    # ./compositor/quickshell.nix
    # ./robbsbro.nix
  ];

  # General User Packages
  home.packages = with pkgs; [
    fastfetch
    btop
    ripgrep
    jq
    eza # Better ls
    bat # Better cat
    nh
  ];

  # Required for `nh` to work without specifying path every time
  home.sessionVariables = {
    NH_FLAKE = "/home/alice/nixos-config";
  };

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
