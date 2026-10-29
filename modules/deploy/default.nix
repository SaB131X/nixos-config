# modules/deploy/default.nix
{ lib, config, pkgs, ... }:

{
  # here we declare options which we'll use in hosts
  options.deploy = {
    target-host.enable = lib.mkEnableOption "Target Host (Remote server that accepts the update)";
    build-host.enable = lib.mkEnableOption "Build Host (Machine that builds system, Self for now)";
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
      programs.ssh.startAgent = lib.mkForce true;
    }
    # mkIf enables all of that for the host once deploy.target-host.enable = true;
    # anywhere in the repo. Remember that it requires config as module inputs(2nd line of that file).
    # Check hosts/laptop/default.nix (~70-80th line) for usage example
    (lib.mkIf config.deploy.target-host.enable {
      services.openssh = {
        enable = lib.mkForce true;
        settings = {
          PubkeyAuthentication = lib.mkForce true;
          AllowAgentForwarding = true;
        };
      };
      # Enable pam_rssh for sudo
      security.pam.services.sudo.rssh = true;
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ 22 ];
      };
      users.users."sab131x" = {
        isNormalUser = true;
        description = "SaB131X";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILW22Iqsoc7j//F7iLEkQUWzOtGJZW65FmT/ASQSPxq6 sea1024wm@gmail.com"
        ];
      };
      nix.settings.trusted-users = [
        "root"
        "sab131x"
        "@wheel"
      ];
    })
    # Same here but for deploy.build-host.enable
    (lib.mkIf config.deploy.build-host.enable {
    })
  ];
}