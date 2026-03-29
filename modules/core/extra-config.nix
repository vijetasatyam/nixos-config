{
  # config,
  # pkgs,
  ...
}: {
  # --- 1. Nix Settings ---
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;

    # Prevent "Buffer Full" warning
    download-buffer-size = 536870912;
  };

  # --- 2. Garbage Collection ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # --- 3. Package Settings ---
  nixpkgs.config.allowUnfree = true;

  # THE FIX: The Python overlays for kubernetes/aiohappyeyeballs have been removed.
  # This stops the "butterfly effect" that forced QEMU and Libvirt to compile from source.

  # --- 5. Technical Debt ---
  system.stateVersion = "25.11";
}
