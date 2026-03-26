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
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # THE FIX: Instantiate unstable exactly ONCE to save massive amounts of RAM
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          # Pass the single instance down
          specialArgs = { inherit inputs pkgs-unstable; };

          modules = [
            ../hosts/nixos/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # Pass the same single instance to Home Manager
              home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };

              home-manager.users.alice = import ../modules/home/home.nix;
            }
          ];
        };
      };
    };
}
