{config, pkgs, ...}:

{
  home.username = "sab131x";
  home.homeDirectory = "/home/sab131x";
  programs = {
    git = {
      enable = true;
      userName = "SaB131X";
      userEmail = "sea1024wm@gmail.com";
      extraConfig.init.defaultBranch = "main";
    };
    gh = {
      enable = true;
      # settings.git_protocol = "https";
      # gitCredentialHelper = {
      #   enable = true;
      #   hosts = [ "github.com" ];
      # };
    };
    yazi = {
      enable = true;
      plugins = {
        git = pkgs.yaziPlugins.git;
      };
    };
    btop.enable = true;
    bash = {
      enable = true;
    };
  };
  home.stateVersion = "26.05";
}
