#/home/alice/nixos-config/modules/home/dev/git-config.nix
{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git
    gnupg
    pinentry-qt
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
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
