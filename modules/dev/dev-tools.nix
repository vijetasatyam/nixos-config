{ config, pkgs, ... }:

{
  # 1. NIX-LD (Required for running unpatched binaries like VSCode extensions)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Common libraries often needed by unpatched binaries
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    glib
    util-linux
  ];

  # 2. System-Wide Dev Packages (Optional, but good for build tools)
  environment.systemPackages = with pkgs; [
    gnumake
    gcc
    pkg-config
    unzip
    wget
    tree
  ];
}
