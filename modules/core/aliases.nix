{
  # config,
  # pkgs,
  ...
}:

{
  environment.shellAliases = {
    # Open the whole folder in VS Code
    # edit = "code ~/nixos-config";

    # OR open the whole folder in Zed
    # edit = "zed ~/nixos-config";

    # System Management
    rebuild = "bash ~/nixos-config/rebuild.sh";
    revert = "bash ~/nixos-config/revert.sh";
    clean = "bash ~/nixos-config/clean.sh";

    check = "sudo nixos-rebuild dry-activate";
    gen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";

    # Garbage Collection & Optimization
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";

    # Upgrade: Updates all channels (Stable + Unstable) and then rebuilds
    upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch";

    # Rollback: Quickly switch to the previous working generation
    rollback = "sudo nixos-rebuild switch --rollback";

    # Navigation & Git
    conf = "cd ~/nixos-config";
    sync = "git push origin main && git push github main";
    edit = "cd ~/nixos-config && vim hosts/nixos/configuration.nix";

    # Shortcuts
    ls = "ls --color=auto";
    ll = "ls -l";
    grep = "grep --color=auto";
  };
}
