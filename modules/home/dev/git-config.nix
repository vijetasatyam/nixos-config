{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    gnupg
    pinentry-gnome3
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  programs.git = {
    enable = true;

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
            # YOUR BRAND NEW KEY ID
            signingkey = 84CCFF76E30A0E07C9C256EB0C343897BCCA0280

          [commit]
            gpgsign = true

          [tag]
            gpgsign = true
        '';
      }
    ];
  };
}
