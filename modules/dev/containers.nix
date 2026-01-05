{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.modules.core.containers = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable container runtimes (Podman, Docker, Distrobox)";
    };
  };

  config = lib.mkIf config.modules.core.containers.enable {

    # --- 1. Real Docker (System-wide Daemon) ---
    virtualisation.docker = {
      enable = true;
      # This provides the traditional /var/run/docker.sock
    };

    # --- 2. Podman (Rootless/User-local) ---
    virtualisation.podman = {
      enable = true;
      # We turn OFF compatibility so 'docker' refers to the real Docker binary,
      # and 'podman' refers to the podman binary. No confusion.
      dockerCompat = false;
      # This enables the rootless socket for your specific user.
      dockerSocket.enable = false;
    };

    # --- 3. Container Tools ---
    environment.systemPackages = with pkgs; [
      distrobox
      podman-compose
      docker-compose
      pods
    ];

    # --- 4. The "Engine Switcher" Logic ---
    # This sets up the default behavior and gives you easy commands to swap
    environment.extraInit = ''
    # Set default DOCKER_HOST to Podman's rootless socket
    # We use a check to ensure XDG_RUNTIME_DIR is set (usually is on login)
      if [ -n "$XDG_RUNTIME_DIR" ]; then
        export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
      fi
    '';

    # --- 5. System Permissions ---
    virtualisation.containers.enable = true;
    users.users.alice.extraGroups = [
      "docker" # Required for real Docker
      "podman" # Required for Podman
    ];
  };
}
