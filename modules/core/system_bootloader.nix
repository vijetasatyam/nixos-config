{
  # config,
  # pkgs,
  # lib,
  ...
}:
{
  # --- 1. Bootloader Configuration ---
  boot.loader.systemd-boot.enable = false; # Explicitly disable the old one
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false; # Prevent conflicts

  # Enable rEFInd
  boot.loader.refind.enable = true;
  boot.loader.refind.maxGenerations = 5;

  boot.loader.refind.extraConfig = ''
    # --- 1. Selection & Global Settings ---
    # Using a string is safer: it picks the first entry containing "NixOS"
    default_selection 3
    timeout 10

    # --- 2. Graphics & Scan Logic ---
    textonly false
    resolution 1920 1080

    # 'internal' ensures Windows is found; 'manual' ensures NixOS entries work
    scanfor internal,manual,external,optical

    # Hide the messy duplicates from systemd-boot
    dont_scan_dirs EFI/systemd, EFI/BOOT
    dont_scan_files systemd-bootx64.efi, BOOTX64.EFI

    # Clean up the tool row and hardware-level duplicates
    scan_pci_roms false

    # --- 3. The Theme (Safe Zone) ---
    icons_dir /EFI/custom-themes/refind-theme-regular/icons/128-48
    big_icon_size 128
    small_icon_size 48

    # THE ICON FIX:
    # rEFInd looks for icons named 'os_<name>.png' to match menuentry names.
    # We point to the theme's background and selection images here.
    banner /EFI/custom-themes/refind-theme-regular/icons/128-48/bg.png
    selection_big /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-big.png
    selection_small /EFI/custom-themes/refind-theme-regular/icons/128-48/selection-small.png
    font /EFI/custom-themes/refind-theme-regular/fonts/source-code-pro-extralight-14.png
  '';

}
