{
  description = "Mohammed's NixOS Flake Configuration";

  inputs = {
    # Core Nix packages - stable release channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Home Manager - matches nixpkgs stable version
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix packages - bleeding edge/unstable channel
    # Used for packages that need the latest versions
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Third-party flakes
    dms-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.mohammed = import ./home/mohammed/home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
