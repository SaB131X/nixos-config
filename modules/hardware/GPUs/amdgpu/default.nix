# modules/hardware/GPUs/amdgpu/default.nix
{ lib, config, pkgs, ... }:

{
  # here we declare options which we'll use in hosts/laptop/default.nix
  options.amdgpu = {
    polaris.enable = lib.mkEnableOption "Enables Polaris (RX400/500) fix for rocm";
    old.enable = lib.mkEnableOption "Enable support for older AMD GPUs (HD8000 and older)";
  };
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
      boot.initrd.kernelModules = [ "amdgpu" ];
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        amdgpu.opencl.enable = true;
      };
      # Set AMD driver for X11/Wayland
      services.xserver.videoDrivers = [ "amdgpu" ];
      nixpkgs.config = {
        allowUnfree = lib.mkDefault true;
        rocmSupport = lib.mkDefault true;
      };
    }

    (lib.mkIf config.amdgpu.polaris.enable {
      environment.variables = {
        ROC_ENABLE_PRE_VEGA = "1";
      };
    })

    # mkIf enables all of that for the host once amdgpu.old.enable = true;
    # anywhere in the repo. Remember that it requires config as module inputs(2nd line of that file).
    (lib.mkIf config.amdgpu.old.enable {
      hardware.amdgpu.legacySupport.enable = true;
      nixpkgs.config = {
        allowUnfree = lib.mkDefault true;
        rocmSupport = lib.mkForce false;
      };
    })
  ];
}