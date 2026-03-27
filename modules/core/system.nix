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

  boot.loader.refind.extraConfig = ''
    # --- 1. Force Graphics Mode ---
    textonly false
    resolution 1920 1080

    # --- 2. Clean up duplicates & messy files ---
    dont_scan_dirs EFI/systemd, EFI/BOOT
    dont_scan_files systemd-bootx64.efi, BOOTX64.EFI

    # --- 3. Clean up the Tool Row ---
    showtools reboot, shutdown, firmware

    # --- 4. The Theme (Directly Integrated) ---
    # We no longer use "include" because NixOS deletes the separate file.
    # Instead, we define the theme settings directly here:
    icons_dir themes/refind-theme-regular/icons/128-48
    big_icon_size 128
    small_icon_size 48

    # You can change these to bg_dark.png and selection_dark... for the dark theme variant
    banner themes/refind-theme-regular/icons/128-48/bg.png
    selection_big themes/refind-theme-regular/icons/128-48/selection-big.png
    selection_small themes/refind-theme-regular/icons/128-48/selection-small.png

    font themes/refind-theme-regular/fonts/source-code-pro-extralight-14.png
  '';

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
