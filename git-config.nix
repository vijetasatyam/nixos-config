{
  config,
  pkgs,
  ...
}:

{
  # Install the necessary binaries for this module
  environment.systemPackages = with pkgs; [
    git
    gnupg
    pinentry-all
  ];

  # GPG Agent Configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  # Git Configuration
  programs.git = {
    enable = true;

    # Global settings (apply everywhere)
    config = {
      init.defaultBranch = "main";
    };

    # Conditional settings (apply ONLY to your config folder)
    includes = [
      {
        condition = "gitdir:~/nixos-config/";
        contents = {
          user = {
            name = "vijetasatyam";
            email = "vijetasatyam@gmail.com";
            signingkey = "3D9E0D76FFDBAFC3";
          };
          commit.gpgsign = true;
          tag.gpgSign = true;
        };
      }
    ];
  };
}
