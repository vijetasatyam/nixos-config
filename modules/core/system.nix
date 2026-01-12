{
  # config,
  # pkgs,
  # lib,
  ...
}:

{
  # Bootloader.

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Locals.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";


  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN.UTF-8"; # Added .UTF-8

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN.UTF-8";
    LC_MEASUREMENT = "en_IN.UTF-8";
    LC_IDENTIFICATION = "en_IN.UTF-8";
    LC_MONETARY = "en_IN.UTF-8";
    LC_NAME = "en_IN.UTF-8";
    LC_NUMERIC = "en_IN.UTF-8";
    LC_PAPER = "en_IN.UTF-8";
    LC_TELEPHONE = "en_IN.UTF-8";
    LC_TIME = "en_IN.UTF-8";
  };
  # # Select internationalisation properties.
  # i18n.defaultLocale = "en_IN";

  # i18n.extraLocaleSettings = {
  #   LC_ADDRESS = "en_IN";
  #   LC_IDENTIFICATION = "en_IN";
  #   LC_MEASUREMENT = "en_IN";
  #   LC_MONETARY = "en_IN";
  #   LC_NAME = "en_IN";
  #   LC_NUMERIC = "en_IN";
  #   LC_PAPER = "en_IN";
  #   LC_TELEPHONE = "en_IN";
  #   LC_TIME = "en_IN";
  # };

}
