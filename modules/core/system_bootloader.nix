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
  boot.loader.refind.maxGenerations = 5;

  boot.loader.refind.extraConfig = ''
    # --- The Settings that will finally stick ---
    default_selection 3
    timeout 10

    textonly false
    resolution 1920 1080

    # Clean up
    dont_scan_dirs EFI/systemd, EFI/BOOT
    dont_scan_files systemd-bootx64.efi, BOOTX64.EFI
    showtools reboot, shutdown, firmware
    scan_pci_roms false
    scanfor manual,external,optical

    # Theme
    icons_dir /EFI/custom-themes/refind-theme-regular/icons/128-48
    big_icon_size 128
    small_icon_size 48
    banner /EFI/custom-themes/refind-theme-regular/icons/128-48/bg.png
    selection_big /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-big.png
    selection_small /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-small.png
    font /EFI/custom-themes/refind-theme-regular/fonts/source-code-pro-extralight-14.png
  '';

  # --- 2. The Nuclear Option (Activation Script) ---
  # This runs after the bootloader is installed and deletes the hardcoded lines NixOS adds
  system.activationScripts.cleanupRefind = ''
    echo "Cleaning up hardcoded NixOS rEFInd defaults..."
    if [ -f /boot/EFI/refind/refind.conf ]; then
      # Delete lines exactly matching 'timeout 5' and 'default_selection 2'
      sed -i '/^timeout 5$/d' /boot/EFI/refind/refind.conf
      sed -i '/^default_selection 2$/d' /boot/EFI/refind/refind.conf
    fi
  '';
}
