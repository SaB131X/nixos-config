{ pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ZRAM setup
  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "lz4";
    memoryPercent = 50;
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking = {
    hostName = "nixos";
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.


    # Enable networking
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 3389 ];
      allowedUDPPorts = [ 24832 3389 ];
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
  services = {
    desktopManager.plasma6 = {
      enable = true;
    };
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."sab131x" = {
    isNormalUser = true;
    description = "SaB131X";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Install firefox.
  programs = {
    firefox.enable = true;
    firejail.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

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
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nh
    # DEV
    git
    # SDKs
    dotnet-sdk_10
    ruby
    # LSPs
    nil
    csharp-ls
    ruby-lsp
    # IDE
    # pulsar

    
    # KDE Utils
    kdePackages.discover
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kclock
    kdePackages.ksystemlog
    kdePackages.sddm-kcm
    # kdePackages.krdp
    kdiff3
    # clipboards
    # wayland-utils
    wl-clipboard
    xclip
    xdg-desktop-portal
  ];
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.kpat
    kdePackages.kmines
    kdePackages.kmahjongg
    kdePackages.ksudoku
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";

}
