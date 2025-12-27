{
  # config,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    git
    gnupg
    pinentry-all
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";

      # This is the NixOS way to do a conditional include.
      # It creates a temporary file with your identity and tells Git to load it
      # only when you are inside the nixos-config directory.
      "includeIf \"gitdir:~/nixos-config/\"" = {
        path = "${pkgs.writeText "gitconfig-nixos" ''
          [user]
            name = vijetasatyam
            email = vijetasatyam@gmail.com
            signingkey = 3D9E0D76FFDBAFC3
          [commit]
            gpgsign = true
          [tag]
            gpgsign = true
        ''}";
      };
    };
  };
}
