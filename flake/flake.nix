{
  description = "Alice's Modular Hybrid Config";

  inputs = {
    # 1. Stable Base
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # 2. Unstable Source
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # 3. Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 4. MangoWC
        mango = {
          url = "github:mangowm/mango";
          inputs.nixpkgs.follows = "nixpkgs";
        };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    mango,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # 1. Define a shared config block
    shared-config = {
      allowUnfree = true;
    };

    # 2. Apply it to the Unstable instance
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = shared-config; # Centralized here
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs pkgs-unstable;};
      modules = [
        ../hosts/nixos/configuration.nix
        # 3. Apply it to the Stable instance via a module
        {nixpkgs.config = shared-config;} # Centralized here

        # Enable the official Mango NixOS module
        mango.nixosModules.mango

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Pass the same single instance to Home Manager
          home-manager.extraSpecialArgs = {inherit inputs pkgs-unstable;};

          home-manager.users.alice = import ../modules/home/home.nix;
        }
      ];
    };
  };
}
