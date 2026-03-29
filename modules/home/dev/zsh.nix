{
  # config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh (The framework for plugins)
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
      ];
      # We intentionally leave the theme blank here so Starship can take over!
    };

    # Aliases (These override system aliases if conflicts exist)
    shellAliases = {
      # Visual upgrades using packages you already have
      ls = "eza --icons --group-directories-first";
      ll = "eza -al --icons --group-directories-first";
      cat = "bat --style=plain";

      # System Management
      rebuild = "bash ~/nixos-config/scripts/rebuild.sh";
      update = "cd ~/nixos-config/flake && nix flake update && rebuild";

      # The Unstable Shell shortcut
      ush = "nix shell github:nixos/nixpkgs/nixos-unstable#$1 --impure";

      # Quick navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      ".3" = "cd ../../..";

      # Git shortcuts (Preserved exactly as you had them)
      g = "git";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
    };

    # Extra Config (e.g. init scripts)
    # Changed from 'initContent' to 'initExtra' to ensure Home Manager injects it perfectly
    initExtra = ''
      # fastfetch on start
      ${pkgs.fastfetch}/bin/fastfetch
    '';
  };
}
