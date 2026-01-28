{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    gnupg
    pinentry-all
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # FIX: Syntax change from 'pinentryPackage' to 'pinentry.package'
    pinentry.package = pkgs.pinentry-all;
  };

  programs.git = {
    enable = true;

    # FIX: Syntax change from 'extraConfig' to 'settings'
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };

    includes = [
      {
        condition = "gitdir:~/nixos-config/";
        path = pkgs.writeText "gitconfig-nixos" ''
          [user]
            name = vijetasatyam
            email = vijetasatyam@gmail.com
            signingkey = 3D9E0D76FFDBAFC3
          [commit]
            gpgsign = true
          [tag]
            gpgsign = true
        '';
      }
    ];
  };
}
