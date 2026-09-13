#/home/alice/nixos-config/modules/core/services.nix
{
  config,
  pkgs,
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

    # Enable UPower for battery/power reporting
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # Enable BlueZ daemon so Quickshell DBus can inspect bluetooth devices
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # Install brightnessctl and grant non-root video group access
    environment.systemPackages = [pkgs.brightnessctl];
    services.udev.packages = [pkgs.brightnessctl];

    # Enable SSH Support
    services.openssh.enable = true;

    # --- CUPS Printing Configuration ---
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        epson-escpr # Epson Inkjet Printer Driver (ESC/P-R) covers L3150
        epsonscan2
        cups-pdf-to-pdf
      ];
    };

    # mDNS/DNS-SD for network printer auto-discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Open CUPS browsing port in the firewall
    networking.firewall = {
      allowedUDPPorts = [631];
    };

    # (Optional) Scanning support via SANE for the L3150 flatbed scanner
    hardware.sane = {
      enable = true;
      extraBackends = [pkgs.utsushi]; # Epson Image Scan v3 backend
    };

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
