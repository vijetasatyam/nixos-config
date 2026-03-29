{
  # config,
  pkgs,
  # lib,
  ...
}: {
  # --- 1. Global Boot Settings ---
  boot.loader.systemd-boot.enable = false;
  boot.loader.refind.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- 2. GRUB Configuration ---
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;

    # Match the resolution of the Sekiro assets
    gfxmodeEfi = "1920x1080";

    # Force the Graphical Terminal and specific modules
    extraConfig = ''
      set gfxpayload=keep
      insmod all_video
      insmod gfxterm
      insmod png
      insmod jpeg
      insmod font
      terminal_output gfxterm
    '';

    # --- 3. Sekiro Theme Derivation ---
    theme = pkgs.stdenv.mkDerivation {
      pname = "sekiro-grub-theme";
      version = "1.0";

      src = pkgs.fetchFromGitHub {
        owner = "AbijithBalaji";
        repo = "sekiro_grub_theme";
        rev = "master";
        # Ensure this hash matches your local 'nix build' result
        hash = "sha256-uXwDjb0+ViQvdesG5gefC5zFAiFs/FfDfeI5t7vP+Qc=";
      };

      installPhase = ''
        mkdir -p $out
        # The Sekiro theme files are in a subfolder in this repo
        # We move everything from the 'Sekiro' folder to the root of $out
        cp -r Sekiro/* $out/

        # GRUB needs a background.png reference usually
        cp $out/sekiro_1920x1080.png $out/background.png
      '';
    };
  };
}
