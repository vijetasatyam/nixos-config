{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.vmware.enable = lib.mkEnableOption "VMware Guest Services";

  config = lib.mkIf config.modules.vmware.enable {
    # This core setting handles the service and kernel drivers
    virtualisation.vmware.guest.enable = true;

    # This makes the command-line utilities available in your terminal
    environment.systemPackages = with pkgs; [
      open-vm-tools
    ];
  };
}
