# modules/apps/flatpack/LinOffice/default.nix
{ lib, config, pkgs, inputs, ... }:

# X86_64 Linux platform only
{
  options.apps.linOffice = {
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # It's me, change to your user, it'll be applied only if you leave linOffice.users as it is
      default = [ "sab131x" ];
      # Some examples
      example = [ "sab131x" "alice" ];
      description = "List of users, which will get LinOffice instance from Home Manager";
    };
    portal = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kdePackages.xdg-desktop-portal-kde;
      example = lib.literalExpression "pkgs.xdg-desktop-portal-gtk";
      description = "The XDG desktop portal implementation to use for LinOffice (Flatpak). By default uses kde";
    };
  };

  config = lib.mkIf (config.apps.linOffice.users != []) {
    virtualisation.podman.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [
      podman-compose
    ];
    services.flatpak.enable = lib.mkDefault true;
    xdg.portal = {
      enable = lib.mkDefault true;
      extraPortals = [ config.apps.linOffice.portal ];
    };
    users.users = lib.genAttrs config.apps.linOffice.users (username: { ... }: {
      extraGroups = [ "kvm" "podman" ];
    });
    home-manager.users = lib.genAttrs config.apps.linOffice.users (username: { ... }: {
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
      home.sessionVariables = {
        XDG_DATA_DIRS = "$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share";
      };
    });
  };
}