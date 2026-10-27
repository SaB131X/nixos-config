# modules/desktopEnv/kde/default.nix
{ lib, config, pkgs, ... }:

{
  # here we declare options which we'll use in hosts/laptop/default.nix
  options.kde = {
    krdp.enable = lib.mkEnableOption "KDE RDP support";
    bluedevil.enable = lib.mkEnableOption "Bluetooth (Bluedevil)";
    audio.enable = lib.mkEnableOption "PipeWire audio";
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
      services = {
        desktopManager.plasma6 = {
          enable = true;
        };
        displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
      };

      environment = {
        systemPackages = with pkgs; [
          # KDE Utils
          kdePackages.kcalc
          kdePackages.kcharselect
          kdePackages.kclock
          kdePackages.ksystemlog
          kdePackages.sddm-kcm
          # kdePackages.krdp
          kdiff3
          # clipboards
          wayland-utils
          wl-clipboard
          xclip
          xdg-desktop-portal
        ];
        plasma6.excludePackages = with pkgs; [
          kdePackages.kpat
          kdePackages.kmines
          kdePackages.kmahjongg
          kdePackages.ksudoku
        ];
      };
    }
    # mkIf enables all of that for the host once kde.krdp.enable = true;
    # anywhere in the repo. Remember that it requires config as module inputs(2nd line of that file).
    # Check hosts/laptop/default.nix (~70-80th line) for usage example
    (lib.mkIf config.kde.krdp.enable {
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 3389 ];
        allowedUDPPorts = [ 3389 ];
      };
      environment.systemPackages = [ pkgs.kdePackages.krdp ];
    })
    # Same here but for kde.bluedevil.enable
    (lib.mkIf config.kde.bluedevil.enable {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      environment.systemPackages = [ pkgs.kdePackages.bluedevil ];
    })
    (lib.mkIf config.kde.audio.enable {
      security.rtkit.enable = true;
      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
    })
  ];
}