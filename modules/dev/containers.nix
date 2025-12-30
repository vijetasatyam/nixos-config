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

    # --- 1. Podman (Primary CLI) ---
    virtualisation.podman = {
      enable = true;
      # NOTE: dockerCompat = true creates the 'docker' alias for the podman command.
      # It does NOT conflict with the Docker daemon socket unless 'dockerSocket.enable' is true.
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # --- 2. Docker (Backend Daemon) ---
    # We keep the real Docker daemon enabled for tools that require the actual .sock file.
    # If you want to go "Podman Only" later, set this to false and set
    # virtualisation.podman.dockerSocket.enable = true.
    virtualisation.docker.enable = false;

    # --- 3. Container Tools ---
    environment.systemPackages = with pkgs; [
      distrobox
      podman-compose
      docker-compose
      pods # Native GTK Podman manager
    ];

    # --- 4. System Settings ---
    virtualisation.containers.enable = true;

    # Add user to groups
    users.users.alice.extraGroups = [
      "podman"
      "docker"
    ];
  };
}
