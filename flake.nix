{
  description = "n3z's NixOS + Home Manager Flake Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    username = "n3z";

    # shared by every host: modules + home-manager wiring
    baseModules = [
      ./nixos/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = { inherit inputs username; };
        home-manager.users.${username} = import ./home/home.nix;
      }
    ];

    mkHost = extraModules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = baseModules ++ extraModules;
      };
  in {
    # bare metal (laptop / desktop) — no virtualisation bits
    nixosConfigurations.n3zer = mkHost [
      ./nixos/profiles/laptop.nix
    ];

    # VirtualBox guest — reuses this machine's hardware config
    nixosConfigurations.n3zer-vm = mkHost [
      ./nixos/profiles/virtualbox-guest.nix
    ];
  };
}
