# hosts/laptop/default.nix
{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./hardware-extras.nix
    ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Use latest kernel.
    kernelPackages = pkgs.linuxPackages_latest;
    # ZRAM swap tweaks
    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  # ZRAM setup
  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "lz4";
    memoryPercent = 50;
  };

  # Nvidia RTX 4070 support
  nvidia.laptop.enable = true;

  networking = {
    # That's your terminal invitation and it also shows in the network you're connected to.
    # Preferebly don't have same hostName on different hosts to avoid network collisions.
    hostName = "nixltp";
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ 24832 ];
    };
    # WG Quick / WG client
    wg-quick.interfaces.wg0 = {
      configFile = "/etc/wireguard/laptop.conf";
    };
  };

  # Set your time zone.
  time.timeZone = "Australia/Perth";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  fonts.packages = with pkgs;[
    #iosevka
    nerd-fonts.symbols-only
  ];

  # Enable KDE Desktop Environment
  kde = {
    krdp.enable = true;
    bluedevil.enable = true;
    audio.enable = true;
  };
  # Support for printers
  services.printing.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."sab131x" = {
    isNormalUser = true;
    description = "SaB131X";
    # wheel lets you use SUDO and networkmanager here is to manage network
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  # Call home-manager here to declare nixdatifier (i plan to move it away later)
  home-manager.users."sab131x" = { ... }: {
    imports = [
      inputs.nixdatifier.homeManagerModules.default
    ];
    programs.nixdatifier = {
      enable = true;
      autostart = true;
    };
  };
  programs = {
    firefox.enable = true;
    firejail.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    zsh.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # this option makes your flake.lock autoupdate every time you do a rebuild
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  environment = {
    systemPackages = with pkgs; [
      nh
      # DEV
      git
      # SDKs
      dotnet-sdk_10
      # LSPs
      nil
      csharp-ls
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";
}
