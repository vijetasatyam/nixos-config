#/home/alice/nixos-config/modules/core/users.nix
{
  # config,
  # pkgs,
  # lib,
  ...
}: {
  # User and Accounts.

  users.users = {
    alice = {
      isNormalUser = true;
      extraGroups = [
          # Core / Privilege
          "wheel"             # Sudo access

          # Hardware Access, Graphics & Audio
          "video"             # Display & backlight access
          "render"            # DRM render nodes (/dev/dri/renderD*) for Vulkan/VA-API/compute
          "audio"             # Direct ALSA/sound card access
          "realtime"          # Realtime scheduling privileges for low-latency PipeWire/JACK

          # Input & Peripheral Control
          "input"             # Access to /dev/input/*
          "uinput"            # Virtual input device creation (Kanata, KMonad)
          "hidraw"            # Raw HID access for gamepads and controller configuration

          # Printing & Scanning
          "lp"                # CUPS printing administration
          "scanner"           # SANE scanner access

          # Networking & Security
          "networkmanager"    # Network/Wi-Fi/VPN configuration without sudo
          # "wireshark"         # Packet capture without root
          "systemd-journal"   # View full system logs via journalctl without sudo
          "tpm"               # TPM access for FIDO2/encryption keys

          # Development, Embedded & Flashing
          "dialout"           # Serial communication (Arduino, Pico, USB-UART)
          "plugdev"           # Hotplugged USB devices (YubiKeys, custom keyboards)
          # "adbusers"          # Android Debug Bridge / Fastboot
          # "openocd"           # JTAG/SWD embedded debugging

          # Virtualization & Containers
          # "docker"            # Docker daemon access without sudo
          # "podman"            # Podman container management
          # "libvirtd"          # Virtual machine management via virt-manager
          "kvm"               # KVM hardware virtualization acceleration

          # System Performance
          # "gamemode"          # Feral GameMode optimization permissions
      ];

      #packages = with pkgs; [
      #  thunderbird
      #];
    };
  };

  # password-less sudo.

  security.sudo.extraRules = [
    {
      users = ["alice"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
