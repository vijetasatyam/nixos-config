{
  # config,
  # pkgs,
  # lib,
  ...
}: {
  # User and Accounts.

  users.users = {
    alice = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];

      #packages = with pkgs; [
      #  thunderbird
      #];
    };
  };

  # password-less sudo.

  security.sudo.extraRules = [
    {
      users = ["alice"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
