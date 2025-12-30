{
  # config,
  pkgs,
  ...
}:

{
  # Programs and Packages.

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:

  # $ nix search wget

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget

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
