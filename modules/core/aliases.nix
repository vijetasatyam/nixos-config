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
    rebuild = "sudo nixos-rebuild switch";
    gen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";

    # Garbage Collection & Optimization
    # This deletes old generations and then deduplicates files to save space
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";

    # Upgrade: Updates all channels (Stable + Unstable) and then rebuilds
    upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch";

    # Rollback: Quickly switch to the previous working generation
    rollback = "sudo nixos-rebuild switch --rollback";

    # Navigation
    conf = "cd ~/nixos-config";

    # Quick Edit (Adjust 'vim' to 'code' or 'zed' if you prefer)
    edit = "cd ~/nixos-config && vim hosts/nixos/configuration.nix";

    # Useful Shortcuts
    ls = "ls --color=auto";
    ll = "ls -l";
    grep = "grep --color=auto";
  };
}
