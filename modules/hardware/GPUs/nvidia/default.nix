# modules/hardware/GPUs/nvidia/default.nix
{ lib, config, pkgs, ... }:

let
  unstablePkgs =
    if pkgs-unstable != null then pkgs-unstable
    else import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      # sha256 = "..."; # для воспроизводимости лучше зафиксировать
    }) {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
in

{
  # here we declare options which we'll use in hosts/laptop/default.nix
  options.nvidia = {
    old.enable = lib.mkEnableOption "Enable support for older Nvidia GPUs";
    laptop.enable = lib.mkEnableOption "Enables extreme power saving mode. GPU IS USED ONLY WHEN CALLED nvidia-offload";
  };
  imports = 
    [ 
       
    ];
  # Each file in nix is options + config underhood.
  # options make options, config apply them.
  # By default when you don't use them you just use nixpkgs as a source of options,
  # and the rest is evaluated as config. 
  # In our case we have unconditional and conditional parts of config.
  # mkMerge allows us to resolve that config as one argslist,
  # where some args won't appear if we don't turn them on
  config = lib.mkMerge [
    # Unconditional part
    {
      # Graphics drivers
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        # Suggest open source drivers as well, good for GTX16xx and newer
        nvidia = {
          package = lib.mkDefault unstablePkgs.linuxPackages.nvidiaPackages.stable;
          open = lib.mkDefault true;
        };
      };
      # Set NVIDIA driver for X11/Wayland
      services.xserver.videoDrivers = [ "nvidia" ];
      nixpkgs.config.allowUnfree = lib.mkDefault true;
    }
    # mkIf enables all of that for the host once nvidia.laptop.enable = true;
    # anywhere in the repo. Remember that it requires config as module inputs(2nd line of that file).
    (lib.mkIf config.nvidia.laptop.enable {
      hardware.nvidia = {
        # Modesetting is required for PRIME offload
        modesetting.enable = true;
        # Enable the NVIDIA settings menu
        nvidiaSettings = true;
        # Put the dGPU to sleep when not in use
        powerManagement = {
          enable = true;
          finegrained = true; # Turns off GPU power completely when idle
        };
        # PRIME Offload
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true; # Creates the convenience `nvidia-offload` wrapper
          };
        };
      };
    })
    # Same here but for nvidia.old.enable
    (lib.mkIf config.nvidia.old.enable {
      # Use old non open-source kernel module
      hardware.nvidia = {
        open = false;
        branch = "legacy_580";
      };
    })
  ];
}
