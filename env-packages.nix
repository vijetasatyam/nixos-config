{
  config,
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
    git
    gnupg # gpg key
    pinentry-all # This provides the popup window for your password
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

  # Git.
  programs.git = {
    enable = true;
    config = {
      user.name = "vijetasatyam";
      user.email = "vijetasatyam@gmail.com";
      init.defaultBranch = "main";
      user.signingkey = "3D9E0D76FFDBAFC3";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };

  # GNUPG.

  # This part is crucial for GPG to work correctly on NixOS
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
