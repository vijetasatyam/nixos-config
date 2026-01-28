{ config, pkgs, ... }:

{
  # --- 1. Nix Settings ---
  # Enable Flakes and the new 'nix' command line tool permanently
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Deduplicate identical files in the store to save space
  nix.settings.auto-optimise-store = true;

  # --- 2. Garbage Collection ---
  # Automatically delete old generations every week to save space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # --- 3. Package Settings ---
  # Allow unfree packages (Chrome, VSCode, Nvidia drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # --- 4. Technical Debt ---
  # Do NOT change this. It defines the state compatibility version.
  system.stateVersion = "25.11";
}
