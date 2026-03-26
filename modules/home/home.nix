{
  #config,
  pkgs,
  #pkgs-unstable,
  ...
}:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  # Import User Configs`
  imports = [
    ./dev/vscode.nix
    ./dev/vscodium.nix
    ./dev/git-config.nix
    ./dev/development-tools.nix
    ./dev/terminal.nix
    ./dev/zsh.nix
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
