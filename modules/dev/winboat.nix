{ pkgs, ... }:

{
  # This adds winboat to the pkgs collection so you can use it anywhere
  nixpkgs.overlays = [
    (final: prev: {
      winboat = final.callPackage /home/alice/nixos-config/extra-apps/winboat/package.nix { };
    })
  ];

  # This actually installs it into the system environment
  environment.systemPackages = [
    pkgs.winboat
  ];
}
