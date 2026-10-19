{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-u.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixdatifier = {
      url = "github:Muddyblack/nixdatifier";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, nixdatifier, ...}@inputs: {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./hosts/laptop
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {
                  inherit inputs;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
              users.sab131x = import ./modules/home;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
  };
}
