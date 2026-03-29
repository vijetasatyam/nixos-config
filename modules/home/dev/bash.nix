{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # History settings
    historyControl = [
      "erasedups"
      "ignorespace"
    ];
    historyFileSize = 10000;
    historySize = 10000;

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      ls = "eza --icons --group-directories-first";
      ll = "eza -al --icons --group-directories-first";
      cat = "bat --style=plain";
      rebuild = "bash ~/nixos-config/scripts/rebuild.sh";
      update = "cd ~/nixos-config/flake && nix flake update && rebuild";
    };

    # Bash-specific options
    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    # Code that runs on startup
    initExtra = ''
      # Print a clean system & environment status
      ${pkgs.fastfetch}/bin/fastfetch
    '';
  };
}
