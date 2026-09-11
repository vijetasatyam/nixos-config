#/home/alice/nixos-config/modules/home/compositor/toggle-wc.nix
{
  pkgs,
  ...
}: let
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

    kill_existing() {
      systemctl --user stop --no-block inir.service 2>/dev/null || true

      # Kill quickshell instances
      pkill -9 -x "quickshell" 2>/dev/null || true

      # Gracefully stop dms backend if running, then kill any lingering processes
      dms kill 2>/dev/null || true
      pkill -9 -x "dms" 2>/dev/null || true

      # Kill inir processes without matching this script ($$) or parent ($PPID)
      for pid in $(pgrep -f "inir" 2>/dev/null); do
        if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
          kill -9 "$pid" 2>/dev/null || true
        fi
      done

      sleep 0.1
    }

    case "$TARGET" in
      dms)
        kill_existing
        echo "dms" > "$STATE_FILE"
        nohup dms run > /tmp/dms.log 2>&1 &
        ;;
      inir)
        kill_existing
        echo "inir" > "$STATE_FILE"
        nohup inir run > /tmp/inir.log 2>&1 &
        ;;
      *)
        echo "Usage: toggle-shell [inir|dms]"
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [
    toggleShellScript
  ];

  systemd.user.services.inir-autostart = {
    Unit = {
      Description = "Auto-start default shell on Niri";
      After = ["niri.service"];
    };
    Install = {
      WantedBy = ["niri.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${toggleShellScript}/bin/toggle-shell inir";
    };
  };
}
