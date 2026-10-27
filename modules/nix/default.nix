# modules/nix/default.nix
{ ... }:

{
  nix = {
    settings = {
      # Tells your system to download stuff if possible instead of building it from source code
      substitute = true;
      always-allow-substitutes = true;
      # Enables auto Hard-Linking in the nix/store after nixos-rebuild to save the disk space
      auto-optimise-store = true;
      # Binary caches (packages mirrors) contain pre-build packages,
      # it's always better to download from them than to build the stuff yourself.
      # To add the new binary cache (packages mirror)
      # simply put it in extra-substituters
      # and add corresponding extra-trusted-public-keys
      # here we have binary caches for nix-community (home-manager),
      # yazi (tui filebrowser),
      # and bunch of chinese caches (they use official tpks so you can just add the link)
      extra-substituters = [
        "https://nix-community.cachix.org"
        # "https://mirror.sjtu.edu.cn/nix-channels/store"
        # "https://mirrors.ustc.edu.cn/nix-channels/store"
        # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://yazi.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
      # This enables flakes and new syntax,
      # the entire repo is build on the flake system so keep it
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}
