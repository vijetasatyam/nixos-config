{
  config,
  # pkgs,
  lib,
  ...
}: {
  options = {
    modules.core.services = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable standard system services (SSH, Audio, Printing)";
      };
    };
  };

  config = lib.mkIf config.modules.core.services.enable {
    # Universal Secret Storage
    services.dbus.enable = true;
    services.gnome.gnome-keyring.enable = true;

    # Enable SSH Support
    services.openssh.enable = true;

    # Enable CUPS to print documents
    services.printing.enable = true;

    # Enable sound with pipewire
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
