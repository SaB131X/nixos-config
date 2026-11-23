# modules/apps/flatpack/LinOffice/default.nix
{ lib, config, pkgs, inputs, ... }:

# X86_64 Linux platform only
{
  virtualisation.podman.enable = lib.mkDefault true;
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
  services.flatpak.enable = lib.mkDefault true;
  users.users."sab131x".extraGroups = [ "kvm" "podman" ];
  home-manager.users."sab131x" = { ... }: {
    imports = [
      # requires `nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";` in flake inputs
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ];
    services.flatpak = {
      enable = true;
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
  };
}