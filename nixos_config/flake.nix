{
  description = "Mohammed's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgsunstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    dms-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgsunstable";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixpkgsunstable, dms-shell, vicinae, ... }@inputs: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
        # Import dms-shell module with unstable packages
        ({ config, lib, pkgs, ... }:
          let
            pkgsUnstable = import nixpkgsunstable {
              system = pkgs.system;
              config.allowUnfree = true;
            };
          in
          {
            imports = [
              (dms-shell.nixosModules.default {
                inherit config lib;
                pkgs = pkgsUnstable;
              })
            ];
          })
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.mohammed = import ./home/mohammed/home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  };
}
