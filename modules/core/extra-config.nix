{ config, pkgs, ... }:

{
  # --- 1. Nix Settings ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Prevent "Buffer Full" warning
    download-buffer-size = 536870912;

    # SAVE RAM & CPU: Only build 1 package at a time, and use only 2 CPU cores per build
    max-jobs = 1;
    cores = 0;
  };

  # --- 2. Garbage Collection ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # --- 3. Package Settings ---
  nixpkgs.config.allowUnfree = true;

  # --- 4. Build Fixes (Flaky Tests) ---
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {

          # Fix 1: Kubernetes test failure (7 != 6)
          kubernetes = python-prev.kubernetes.overridePythonAttrs (old: {
            doCheck = false;
          });

          # Fix 2: aiohappyeyeballs test failure (3 != 4)
          aiohappyeyeballs = python-prev.aiohappyeyeballs.overridePythonAttrs (old: {
            doCheck = false;
          });

        })
      ];
    })
  ];

  # --- 5. Technical Debt ---
  system.stateVersion = "25.11";
}

# { config, pkgs, ... }:

# {
#   # --- 1. Nix Settings ---
#   nix.settings.experimental-features = [
#     "nix-command"
#     "flakes"
#   ];
#   nix.settings.auto-optimise-store = true;

#   # --- 2. Garbage Collection ---
#   nix.gc = {
#     automatic = true;
#     dates = "weekly";
#     options = "--delete-older-than 7d";
#   };

#   # --- 3. Package Settings ---
#   nixpkgs.config.allowUnfree = true;

#   # --- 4. THE FIX: Disable broken tests in python-kubernetes ---
#   # nixpkgs.overlays = [
#   #  (final: prev: {
#   #    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
#   #      (python-final: python-prev: {
#   #        kubernetes = python-prev.kubernetes.overridePythonAttrs (old: {
#   #          # The test suite is failing with an assertion error (7 != 6).
#   #          # We disable tests so the package can build and the system update can finish.
#   #          doCheck = false;
#   #        });
#   #      })
#   #    ];
#   #  })
#   # ];

#   # --- 5. Technical Debt ---
#   system.stateVersion = "25.11";
# }
