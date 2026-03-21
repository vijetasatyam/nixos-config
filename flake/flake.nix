{
  description = "Alice's Modular Hybrid Config";

  inputs = {
    # 1. Stable Base (Matches your system.stateVersion = "25.11")
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # 2. Unstable Source (For specific apps like Neovim/VSCode)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # 3. Home Manager (Matched to Stable 25.11)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        # Hostname "nixos" matches your configuration.nix [cite: 29]
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          # Pass 'pkgs-unstable' to System Modules
          specialArgs = {
            inherit inputs;
            pkgs-unstable = import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };

          modules = [
            # Import existing system config (Adjusted path for flake/ subdir)
            ../hosts/nixos/configuration.nix

            # Enable Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # Pass 'pkgs-unstable' to Home Manager Modules
              home-manager.extraSpecialArgs = {
                inherit inputs;
                pkgs-unstable = import nixpkgs-unstable {
                  system = "x86_64-linux";
                  config.allowUnfree = true;
                };
              };

              # Import your new User Hub
              home-manager.users.alice = import ../modules/home/home.nix;
            }
          ];
        };
      };
    };
}
