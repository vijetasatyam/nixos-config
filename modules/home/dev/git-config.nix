{pkgs, ...}: {
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
            signingkey = 6D6783A58A88C6D07F9D2A6BDF58C829520F1B07

          [commit]
            gpgsign = true

          [tag]
            gpgsign = true
        '';
      }
    ];
  };
}
