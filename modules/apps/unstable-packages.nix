{
  config,
  ...
}:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };
in
{
  environment.systemPackages = [
    # Obsidian works great from unstable
    unstable.obsidian

    # Recommended: Vesktop instead of Discord for better Wayland support
    unstable.vesktop

    # Or, if you prefer the official one:
    # (unstable.discord.override { withVencord = true; })
  ];

  # This variable fixes blurry text and screen sharing for Obsidian/Discord
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
