{
  # config,
  # pkgs,
  # lib,
  ...
}: {
  # boot.kernelParams = ["usb-storage.quirks=0781:55a9:u"];
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
