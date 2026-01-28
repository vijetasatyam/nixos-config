{
  # config,
  # pkgs,
  ...
}:

{
  imports = [
    # --- Machine Specific ---
    ./hardware-configuration.nix

    # --- Core System Modules ---
    ../../modules/core/aliases.nix
    ../../modules/core/extra-config.nix
    ../../modules/core/flathub.nix
    ../../modules/core/networking.nix
    ../../modules/core/services.nix
    ../../modules/core/system.nix
    ../../modules/core/users.nix
    ../../modules/core/vmware.nix

    # --- NEW: System Restrictions (Hosts file blocking) ---
    ../../modules/core/blocklist.nix

    # --- Application Modules (System Wide) ---
    ../../modules/apps/env-packages.nix
    ../../modules/apps/unstable-packages.nix

    # --- System-Level Dev Modules (VMs, Docker, Winboat) ---
    # NOTE: These MUST stay in system config, they use virtualisation.* options
    ../../modules/dev/dev-tools.nix
    ../../modules/dev/virtual-machines.nix
    ../../modules/dev/winboat.nix
  ];

  # Enable VMware Guest modules if needed
  modules.vmware.enable = true;
}
