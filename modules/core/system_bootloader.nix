{
  # config,
  pkgs,
  # lib,
  ...
}: {
  # --- 1. Bootloader Configuration ---
  boot.loader.systemd-boot.enable = false; # Explicitly disable the old one
  boot.loader.refind.enable = false; # Explicitly disable rEFInd

  boot.loader.efi.canTouchEfiVariables = true;

  # --- 2. Enable GRUB ---
  boot.loader.grub = {
    enable = true;
    device = "nodev"; # 'nodev' is required for EFI systems
    efiSupport = true;
    useOSProber = true; # This automatically finds Windows on your second NVMe

    # --- 3. Sekiro Theme Setup ---
    theme = pkgs.stdenv.mkDerivation {
      pname = "sekiro-grub-theme";
      version = "1.0";
      src = pkgs.fetchFromGitHub {
        owner = "AbijithBalaji";
        repo = "sekiro_grub_theme";
        rev = "master";
        # We use a fake hash first. Nix will fail on the first build and give you the real one!
        hash = "sha256-uXwDjb0+ViQvdesG5gefC5zFAiFs/FfDfeI5t7vP+Qc=";
      };
      installPhase = ''
        mkdir -p $out
        cp -r ./* $out/
      '';
    };
  };
}
