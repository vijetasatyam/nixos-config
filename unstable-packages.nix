{ config, ... }:

let
  # Import the unstable channel
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };
in
{
  environment.systemPackages = with unstable; [
    # Put all your unstable packages here
    vscodium

    nix-ld

    # lanuage server for .nix file
    nixd
    nil

    # You can add more here later, for example:
    # discord
    # obsidian
    # podman
  ];

  # Program specific settings and services.

  # nix-ld
  programs.nix-ld.enable = true;
}
