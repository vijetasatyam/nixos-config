#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  dmsPackage = inputs.dms.packages.${pkgs.system}.default or pkgs.writeShellScriptBin "dms" ''
    quickshell -p ${inputs.dms}
  '';
in {
  home.packages = [
    dmsPackage
  ];

  # Expose a toggle script to switch shells on the fly
  home.file.".local/bin/switch-shell".source = pkgs.writeShellScript "switch-shell" ''
    case "$1" in
      dms)
        systemctl --user stop inir.service 2>/dev/null || pkill -f inir
        pkill -f quickshell 2>/dev/null || true
        quickshell -p ${inputs.dms} &
        ;;
      inir)
        pkill -f quickshell 2>/dev/null || true
        systemctl --user restart inir.service 2>/dev/null || inir &
        ;;
      *)
        echo "Usage: switch-shell [inir|dms]"
        ;;
    esac
  '';
}
