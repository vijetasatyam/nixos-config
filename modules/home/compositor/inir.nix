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
    # Prevent automatic hard-start so switch-shell can manage toggling
    service.compositor = null;
    extraPackages = [
      pkgs.niri
      pkgs.easyeffects
    ];
    configSymlink.enable = true;
  };
}
