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
    #./compositor/mangowc.nix
    #./compositor/waybar.nix
  ];

  # General User Packages
  home.packages = with pkgs; [
    fastfetch
    btop
    ripgrep
    jq
    eza # Better ls
    bat # Better cat
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
