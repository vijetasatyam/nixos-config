{
  # config,
  # pkgs,
  # lib,
  ...
}:

{
  # --- Bootloader ---
  boot.loader.systemd-boot.enable = false; # Explicitly disable the old one
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable rEFInd
  boot.loader.refind.enable = true;

  # THE FIX: Explicitly disable GRUB to stop the "Failed assertions" error
  boot.loader.grub.enable = false;

  # Add a timeout so you can see the menu (default is often 0 or 1)
  boot.loader.timeout = 10;
  # # Bootloader
  # # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub.enable = false;
  # boot.loader.refind.enable = true;
  # Timezone (Keeping physical location correct)
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties
  # "Keep everything US" -> Setting all locales to en_US.UTF-8
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
}
