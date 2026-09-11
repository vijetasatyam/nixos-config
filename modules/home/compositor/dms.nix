#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  dmsPackage = pkgs.writeShellScriptBin "dms" ''
    exec ${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell -p ${inputs.dms} "$@"
  '';

  toggleShellScript = pkgs.writeShellScriptBin "toggle-shell" ''
    STATE_FILE="''${XDG_RUNTIME_DIR:-/run/user/$UID}/active_shell"
    CURRENT="inir"
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    fi

    TARGET="$1"
    if [ -z "$TARGET" ]; then
      if [ "$CURRENT" = "inir" ]; then
        TARGET="dms"
      else
        TARGET="inir"
      fi
    fi

    case "$TARGET" in
      dms)
        echo "Switching to DankMaterialShell (DMS)..."
        systemctl --user stop inir.service 2>/dev/null || true
        pkill -f inir 2>/dev/null || true
        pkill -f quickshell 2>/dev/null || true
        sleep 0.2
        ${dmsPackage}/bin/dms >/dev/null 2>&1 &
        echo "dms" > "$STATE_FILE"
        ;;
      inir)
        echo "Switching to iNiR..."
        pkill -f quickshell 2>/dev/null || true
        sleep 0.2
        systemctl --user restart inir.service 2>/dev/null || inir >/dev/null 2>&1 &
        echo "inir" > "$STATE_FILE"
        ;;
      *)
        echo "Usage: toggle-shell [inir|dms]"
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [
    dmsPackage
    toggleShellScript
  ];

  # Default initial startup on login: starts iNiR cleanly
  systemd.user.services.inir-autostart = {
    Unit = {
      Description = "Auto-start default shell on Niri";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${toggleShellScript}/bin/toggle-shell inir";
      Restart = "on-failure";
    };
  };
}
