#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  dmsPkg = inputs.dms.packages.${pkgs.system}.default;
in {
  home.packages = [
    inputs.quickshell.packages.${pkgs.system}.default
    dmsPkg
  ];
}
