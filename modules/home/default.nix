{config, pkgs, ...}:

{
  home.username = "sab131x";
  home.homeDirectory = "/home/sab131x";
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "SaB131X";
          email = "sea1024wm@gmail.com";
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
    gh = {
      enable = true;
    };
    yazi = {
      enable = true;
      plugins = with pkgs.yaziPlugins; {
        git.package = git;
      };
    };
    btop.enable = true;
    bash = {
      enable = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion = {
        enable = true;
      };
      fastSyntaxHighlighting = {
        enable = true;
        theme = "default";
      };
      oh-my-zsh = {
        enable = true;
      };
    };
    atuin = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "15m";
        search_mode = "fuzzy";
      };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        format = "$nix_shell \\[$username@$hostname:$directory\\] $git_branch$git_status";
        add_newline = false;
        nix_shell = {
          format = "[$symbol]($style)";
          symbol = "\\[nix-shell\\]";
          style = "bold bold";
        };
        username = {
          style_user = "bold bold";
          show_always = true;
          format = "$user";
        };
        hostname = {
          style = "bold bold";
          ssh_only = false;
          format = "$hostname";
        };
        directory = {
          style = "bold bold";
          format = "$path";
          truncation_length = 0;
          truncate_to_repo = true;
        };
        git_branch = {
          format = "[$branch]($style) ";
          style = "bold purple";
        };
        git_status = {
          format = "[$all_status$ahead_behind]($style) ";
          style = "bold red";
        };
      };
    };
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      systemd.enable = true;
      settings = {
        background-opacity = 0.73;
        # shell-integration-features = "ssh-env,ssh-terminfo";
      };
    };
  };
  home.stateVersion = "26.05";
}
