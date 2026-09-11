#/home/alice/nixos-config/modules/home/home.nix
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
    ./compositor/inir.nix
    ./compositor/dms.nix
    ./compositor/toggle-wc.nix
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
