# modules/hardware/zramswap/default.nix
{ lib, config, pkgs, ... }:

{
  # here we declare options which we'll use in hosts/laptop/default.nix
  options.zramswap = {
    ramtank.enable = lib.mkEnableOption "Zram Swap for cases when you can sac the latency for more swap size";
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
      boot = {
        # ZRAM swap tweaks
        kernel.sysctl = {
          "vm.swappiness" = lib.mkDefault 180;
          "vm.vfs_cache_pressure" = lib.mkDefault 50;
        };
      };
      # ZRAM setup
      zramSwap = {
        enable = lib.mkDefault true;
        priority = lib.mkDefault 100;
        algorithm = lib.mkDefault "lz4";
        memoryPercent = lib.mkDefault 50;
      };
    }

    # mkIf enables all of that for the host once zramswap.ramtank.enable = true;
    # anywhere in the repo. Remember that it requires config as module inputs(2nd line of that file).
    (lib.mkIf config.zramswap.ramtank.enable {
      zramSwap = {
        algorithm = "zstd";
        memoryPercent = 100;
      };
    })
  ];
}