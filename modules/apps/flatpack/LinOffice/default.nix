# modules/apps/flatpack/LinOffice/default.nix
{ lib, config, pkgs, ... }:

{
  virtualisation.podman.enable = lib.mkDefault true;
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
  users.users."sab131x".extraGroups = [ "kvm" "podman" ];
  services.flatpak = {
    enable = lib.mkDefault true;
    packages = [
      {
        appId = "io.github.eylenburg.LinOffice";
        origin = "linoffice";
      }
    ];
    remotes = [
      {
      name = "linoffice";
      location = "https://eylenburg.github.io/linoffice/index.flatpakrepo";
      }
    ];
  };
}