{
  config,
  # pkgs,
  lib,
  ...
}: {
  # 1. Define the Option (Defaulting to TRUE)
  options = {
    modules.core.services = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable standard system services (SSH, GNOME, Audio)";
      };
    };
  };

  # 2. The Logic (Only runs if enabled)
  config = lib.mkIf config.modules.core.services.enable {
    # Universal Secret Storage
    services.dbus.enable = true;
    services.gnome.gnome-keyring.enable = true;

    # Enable SSH Support.
    services.openssh.enable = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
