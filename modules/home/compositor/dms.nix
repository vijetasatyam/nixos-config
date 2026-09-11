#/home/alice/nixos-config/modules/home/compositor/dms.nix
{
  pkgs,
  inputs,
  ...
}: let
  qsBin = "${inputs.quickshell.packages.${pkgs.system}.default}/bin/quickshell";

  # DMS package wrapper: checks if entry is in root or in a quickshell/ subfolder
  dmsPackage = pkgs.writeShellScriptBin "dms" ''
    ENTRY="${inputs.dms}"
    if [ -d "${inputs.dms}/quickshell" ]; then
      ENTRY="${inputs.dms}/quickshell"
    fi
    exec ${qsBin} -p "$ENTRY" "$@"
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

    # Kill running processes safely without killing this script
    kill_existing() {
      systemctl --user stop --no-block inir.service 2>/dev/null || true
      pkill -9 -x "quickshell" 2>/dev/null || true
      pkill -9 -f "/bin/inir" 2>/dev/null || true
      pkill -9 -x "inir" 2>/dev/null || true
      sleep 0.1
    }

    case "$TARGET" in
      dms)
        kill_existing
        echo "dms" > "$STATE_FILE"
        nohup ${dmsPackage}/bin/dms > /tmp/dms.log 2>&1 &
        ;;
      inir)
        kill_existing
        echo "inir" > "$STATE_FILE"
        nohup inir > /tmp/inir.log 2>&1 &
        ;;
      *)
        echo "Usage: toggle-shell [inir|dms]"
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [
    inputs.quickshell.packages.${pkgs.system}.default
    dmsPackage
    toggleShellScript
  ];

  systemd.user.services.inir-autostart = {
    Unit = {
      Description = "Auto-start default shell on Niri";
      After = [ "niri.service" ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${toggleShellScript}/bin/toggle-shell inir";
    };
  };
}
