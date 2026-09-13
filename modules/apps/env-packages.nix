#/home/alice/nixos-config/modules/apps/env-packages.nix
{
  # config,
  pkgs,
  ...
}: {
  # Programs and Packages.

  # List packages installed in system profile. To search, run:

  # $ nix search wget

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    fastfetch
    btop
    htop
    kdePackages.dolphin
    kdePackages.ark
    nautilus
    file-roller
    p7zip
    unzip
    zip
    unrar
    gnutar
    xz
    bzip2
    gzip
    zstd
    vlc
    photoqt
    swww

    # nix versioning tools
    nvd
    nvdtools
    nix-diff
  ];

  # Program specific settings and services.

  # Firefox.
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
      };
    };
  };
}
