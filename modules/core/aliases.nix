{
  # config,
  # pkgs,
  # lib,
  ...
}:

{
  environment.shellAliases = {
    # --- System Management ---
    rebuild = "bash ~/nixos-config/scripts/rebuild.sh";
    revert  = "bash ~/nixos-config/scripts/revert.sh";
    clean   = "bash ~/nixos-config/scripts/clean.sh";

    # Dry-run to check for errors before applying
    check   = "sudo nixos-rebuild dry-activate";
    # List all system generations
    gen     = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";

    # Garbage Collection & Optimization
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";

    # Upgrade: Updates all channels (Stable + Unstable) and then rebuilds
    upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch";

    # Rollback: Quickly switch to the previous working generation
    rollback = "sudo nixos-rebuild switch --rollback";

    # --- Navigation & Configuration ---
    conf = "cd ~/nixos-config";
    edit = "cd ~/nixos-config && zed .";
    sync = "git push origin main && git push github main";

    # --- Development & Containers ---
    # Switch between Podman (Rootless/Privacy) and Real Docker (Daemon)
    use-docker = "export DOCKER_HOST=unix:///var/run/docker.sock";
    use-podman = "export DOCKER_HOST=unix://\$XDG_RUNTIME_DIR/podman/podman.sock";

    # VSCodium Shortcuts
    codium-isolated = "vscodium --user-data-dir ~/.config/VSCodium-Isolated";

    # --- Quality of Life ---
    ls    = "ls --color=auto";
    ll    = "ls -l";
    grep  = "grep --color=auto";
    ".."  = "cd ..";
    "..." = "cd ../..";
  };

  # This ensures that even in subshells or different environments,
  # the DOCKER_HOST defaults to the privacy-focused Podman socket.
  environment.variables = {
    DOCKER_HOST = "unix://\$XDG_RUNTIME_DIR/podman/podman.sock";
  };
}
