{ config, pkgs, ... }:

{
  # Programs and Packages.

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:

  # $ nix search wget

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git

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

  programs.git = {
    enable = true;
    config = {
      user.name = "vijetasatyam";
      user.email = "vijetasatyam@gmail.com"; # Must match your Codeberg email
      init.defaultBranch = "main";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
