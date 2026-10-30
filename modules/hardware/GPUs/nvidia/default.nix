# modules/hardware/GPUs/nvidia/default.nix
{ lib, config, pkgs, ... }:

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
          package = lib.mkDefault (config.boot.kernelPackages.nvidiaPackages.mkDriver {
            # New Driver for GTX16s+
            version = "615.78.08";
            sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
            settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
            # Hash for open modules (open-gpu-kernel-modules)
            openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
            persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
            usePersistenced = false;
          });
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
        # Lets PRIME completely disable dGPU
        nvidiaPersistenced = false;
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
        # Builds the driver pkg for GTX10s (Tested) or older
        package = lib.mkDefault (config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "580.178.04";
          sha256_64bit = "sha256-WXWobuRb/8tib1GuM9EWmxCBhqLqR61lHnLxP6S21vk=";
          sha256_aarch64 = ""; # not fetched
          openSha256 = ""; # not fetched
          settingsSha256 = "sha256-KcrGHoR+ZMdsFyI4myU8/eVls2f8GkNSX/j2JnZndyM=";
          usePersistenced = false;
        });
      };
    })
  ];
}
