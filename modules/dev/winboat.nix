{ pkgs, pkgs-unstable, ... }:

{
  # This adds winboat to the pkgs collection so you can use it anywhere
  nixpkgs.overlays = [
    (final: prev: {
      winboat = final.callPackage ../../extra-apps/winboat/package.nix { };
      nodejs = pkgs-unstable.nodejs_24;
    })
  ];

  # This actually installs it into the system environment
  environment.systemPackages = [
    pkgs.winboat
  ];
}
