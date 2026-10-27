# hosts/wsl/default.nix
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{ config, lib, pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  
  networking.resolvconf.enable =lib.mkForce false;
  # this option makes your flake.lock autoupdate every time you do a rebuild
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  nix.settings.trusted-users = [ "root" "nixos" "@wheel" ];

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    gh
    yazi
    curl
    wget
    btop
    openssh
  ];

  fonts.packages = with pkgs;[
    nerd-fonts.symbols-only
  ];

  systemd.user.services.flatpak-portal.enable = false;
  systemd.services."user-runtime-dir@" = {
    overrideStrategy = "asDropin";
    unitConfig.ConditionPathExists = "!/run/user/%i";
  };
  systemd.tmpfiles.settings.wsl = {
    "/usr/share/applications".L = {
      argument = "/run/current-system/sw/share/applications";
    };
    "/usr/share/icons".L = {
      argument = "/run/current-system/sw/share/icons";
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}