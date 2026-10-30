# flake.nix
{
  # Each flake.nix file contains Inputs (package sources) and outputs (what to build).
  # In inputs we declare package sources
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-u.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixdatifier = {
      url = "github:Muddyblack/nixdatifier";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  # In outputs we declare hosts, packages and other stuff
  # that we get using these packages from inputs
  # in first line we just pass all sources from inputs to the local variable called inputs
  outputs = { self, nixpkgs, nixpkgs-u, nixos-wsl, home-manager, nixdatifier, ...}@inputs: {
    # nixosConfigurations is used to declare hosts that will be avaliable under 
    # in nixos-rebuild switch --flake .#hostName
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        # That parameter tells nix which packages to use 
        # (for x86/x64, aarch (ARM) or darvin (apple@co stuff) CPU's)
        system = "x86_64-linux";
        # That line tells nix that it should pass inputs to everything stated in modules
        specialArgs = { 
          inherit inputs;
          pkgs-unstable = import nixpkgs-u {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        # Here you declare which modules that host should use 
        modules = [
          ./hosts/laptop
          ./modules/nix
          ./modules/desktopEnv/kde
          ./modules/hardware/GPUs/nvidia
          ./modules/deploy
          # That's the Home Manager installation as a flake module 
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              # We pass inputs once more but this time to the Home Manager
              extraSpecialArgs = {
                inherit inputs;
              };
              # These 2 settings tell nix to use existing packages if possible
              useGlobalPkgs = true;
              useUserPackages = true;
              # That one tells where the Home Manager module is
              users.sab131x = import ./modules/home;
              backupFileExtension = "backup";
            };
          }
        ];
      };
      wsl = nixpkgs-u.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/wsl
          ./modules/nix
          # That's a special module for wsl because without it nix doesn't builds on wsl
          nixos-wsl.nixosModules.wsl
        ];
      };
    };

    # Here i expose flake modules that you can use by either
    # adding it to the Flake.nix:
    # 1. inputs = { sbxflake.url ="github:SaB131X/nixos-config";}
    # 2. modules [sbxflake.nixosModules.kde];
    # adding it to the Configuration.nix:
    # 1. imports = [inputs.sbxflake.nixosModules.kde]; (if you haven't added it in flake module; adding it in the inputs is still required)
    # 2. kde.audio.enable = true;
    nixosModules = {
      deploy = import ./modules/deploy;
      nix = import ./modules/nix;
      kde = import ./modules/desktopEnv/kde;
      nvidia = import ./modules/hardware/GPUs/nvidia;
    };

    # FAST CHECK (CI & LOCAL)
    # That part let's us use nix flake check to see if everything is fine or not
    checks = {
      x86_64-linux = let
        # Func: make "fake" drv, which forces all cfg eval,
        # Output: file with path to the .drv file.
        evalCheck = name: config:
          let
            # Here we ask system to give drvPath which means that it must calculate everything first
            drvPath = config.config.system.build.toplevel.drvPath;
          in
          nixpkgs.legacyPackages.x86_64-linux.runCommand "${name}-eval-check" {} ''
            echo "Evaluated ${name}: ${drvPath}" > $out
          '';
        moduleCheck = name: module:
          let
            # make minimal fictional system
            testConfig = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                module
                {
                  fileSystems."/" = nixpkgs.lib.mkDefault {
                    device = "none";
                    fsType = "tmpfs";
                  };
                  boot.loader.grub.devices = nixpkgs.lib.mkDefault [ "nodev" ];
                  system.stateVersion = nixpkgs.lib.mkDefault "26.05";
                }
              ];
            };
            # Same trick here
            drvPath = testConfig.config.system.build.toplevel.drvPath;
          in
          nixpkgs.legacyPackages.x86_64-linux.runCommand "${name}-module-check" {} ''
            echo "Module evaluated ${name}: ${drvPath}" > $out
          '';
      in {
        # Here we run our tests
        laptop = evalCheck "laptop" self.nixosConfigurations.laptop;
        wsl = evalCheck "wsl" self.nixosConfigurations.wsl;
        # New Modules
        deploy = moduleCheck "deploy" self.nixosModules.deploy;
        nix = moduleCheck "nix" self.nixosModules.nix;
        kde = moduleCheck "kde" self.nixosModules.kde;
        nvidia = moduleCheck "nvidia" self.nixosModules.nvidia;
      };
    };
  };
}
