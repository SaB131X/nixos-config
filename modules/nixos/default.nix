{ ... }:

{
  nix = {
    settings = {
      substitute = true;
      always-allow-substitutes = true;
      auto-optimise-store = true;
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
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}
