{
  # config,
  # pkgs,
  pkgs-unstable,
  ...
}: {
  environment.systemPackages = [
    # Obsidian works great from unstable
    pkgs-unstable.obsidian

    # Recommended: Vesktop instead of Discord for better Wayland support
    pkgs-unstable.vesktop

    # If you prefer standard Discord:
    # pkgs-unstable.discord
  ];

  # This variable fixes blurry text and screen sharing for Obsidian/Discord
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
