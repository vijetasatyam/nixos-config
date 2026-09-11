#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  qsBin = "${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell";

  dmsPackage = pkgs.writeShellScriptBin "dms" ''
    export DMS_SOCKET="''${DMS_SOCKET:-''${XDG_RUNTIME_DIR:-/run/user/$UID}/dms.sock}"

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

  home.sessionVariables = {
    DMS_SOCKET = "\${XDG_RUNTIME_DIR}/dms.sock";
  };
}
