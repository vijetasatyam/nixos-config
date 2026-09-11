#/home/alice/nixos-config/modules/home/compositor/swaync.nix
{
  # pkgs,
  # theme,
  ...
}: {
  services.swaync = {
    enable = true;
    # You can further customize the JSON/CSS for SwayNC here,
    # but the default styling works great out of the box with Catppuccin.
  };
}
