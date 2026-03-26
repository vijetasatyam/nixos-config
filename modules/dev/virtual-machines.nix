{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./containers.nix
    ./winboat.nix
  ];

  options.modules.core.virtualisation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable KVM/QEMU virtualization and VM tools";
    };
  };

  config = lib.mkIf config.modules.core.virtualisation.enable {
    # --- 1. KVM / Libvirt ---
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_full;
        runAsRoot = true;
      };
    };

    # --- 2. Advanced Boot & Hardware ---
    boot.extraModprobeConfig = "options kvm_intel nested=1";
    virtualisation.spiceUSBRedirection.enable = true;

    # --- 3. GUI & Tools ---
    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      quickemu
      quickgui
      gnome-boxes
      freerdp
      remmina
    ];

    # --- 4. User Permissions ---
    users.users.alice.extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };
}
