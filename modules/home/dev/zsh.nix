{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh (The framework for plugins/themes)
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = "robbyrussell"; # The classic default. Try "agnoster" or "powerlevel10k" later if you want.
    };

    # Aliases (These override system aliases if conflicts exist)
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";

      # Quick navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      ".3" = "cd ../../..";

      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
    };

    # Extra Config (e.g. init scripts)
    initContent = ''
      # fastfetch on start
      fastfetch
    '';
  };
}
