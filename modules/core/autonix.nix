{
  # config,
  # pkgs,
  ...
}:
{
  systemd.services.autonix = {
    description = "Autonix Background Daemon";

    # Start automatically on boot
    wantedBy = [ "multi-user.target" ];

    # Wait for the network to be up before starting (if autonix needs internet)
    after = [ "network.target" ];

    serviceConfig = {
      # The absolute path to your binary
      ExecStart = "/home/alice/.local/bin/autonix";

      # Run it as your user so it has the right permissions
      User = "alice";
      Group = "users";

      # Auto-restart logic if it crashes
      Restart = "on-failure";
      RestartSec = "5s";

      # Pass environment variables if autonix needs them
      # Environment = "PATH=/run/current-system/sw/bin";
    };
  };
}
