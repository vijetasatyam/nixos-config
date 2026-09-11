#/home/alice/nixos-config/modules/core/niri.nix
{pkgs, ...}: {
  # Enable Niri at the system level
  programs.niri.enable = true;

  # Polkit is required for privilege escalation in Wayland (e.g., GUI sudo)
  security.polkit.enable = true;

  # Use greetd as a lightweight Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Drops you into a TUI login screen, logs into Niri upon success
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "alice";
      };
    };
  };

  # Hint Electron apps to use Wayland natively
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
