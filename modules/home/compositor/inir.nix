#/home/alice/nixos-config/modules/home/compositor/inir.nix
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.inir.homeModules.inir
  ];

  programs.inir = {
    enable = true;
    # Keep compositor auto-start manual or set to "niri"
    # To run iNiR as the primary active service on session start:
    service.compositor = "niri";
    extraPackages = [
      pkgs.niri
      pkgs.easyeffects
    ];
    configSymlink.enable = true;
  };
}
