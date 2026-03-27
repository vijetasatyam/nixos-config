{
  # config,
  # pkgs,
  # lib,
  ...
}: {
  # --- 1. Bootloader Configuration ---
  boot.loader.systemd-boot.enable = false; # Explicitly disable the old one
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false; # Prevent conflicts

  # Enable rEFInd
  boot.loader.refind.enable = true;

  boot.loader.refind.extraConfig = ''
    # --- 1. Clean UI & Selection ---
    # Sets the 3rd icon as the default choice automatically
    default_selection 3
    # Wait 10 seconds before auto-booting inside rEFInd
    timeout 10

    # --- 2. Graphics Mode ---
    textonly false
    resolution 1920 1080

    # --- 3. Declutter Menu & Tools ---
    # Hide systemd-boot files and generic fallbacks to prevent duplicates
    dont_scan_dirs EFI/systemd, EFI/BOOT
    dont_scan_files systemd-bootx64.efi, BOOTX64.EFI

    # FIX: Explicitly define the tool row to prevent double-listing
    showtools reboot, shutdown, firmware

    # --- 4. The Theme (From the "Safe Zone" outside rEFInd folder) ---
    icons_dir /EFI/custom-themes/refind-theme-regular/icons/128-48
    big_icon_size 128
    small_icon_size 48

    banner /EFI/custom-themes/refind-theme-regular/icons/128-48/bg.png
    selection_big /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-big.png
    selection_small /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-small.png

    font /EFI/custom-themes/refind-theme-regular/fonts/source-code-pro-extralight-14.png
  '';
}
