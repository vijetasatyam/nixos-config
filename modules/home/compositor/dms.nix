#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  qsBin = "${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell";

  dmsPackage = pkgs.writeShellScriptBin "dms" ''
    ENTRY="${inputs.dms}"
    if [ -d "${inputs.dms}/quickshell" ]; then
      ENTRY="${inputs.dms}/quickshell"
    fi
    exec ${qsBin} -p "$ENTRY" "$@"
  '';
in {
  home.packages = [
    inputs.quickshell.packages.${pkgs.system}.default
    dmsPackage
  ];
}
