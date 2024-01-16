{ pkgs, ... }:

{
  # https://mipmip.github.io/home-manager-option-search/

  # add home-manager user settings here
  home.packages = with pkgs; [ git ripgrep fd ];
  home.stateVersion = "23.11";

  programs.direnv = { 
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true; 
    };

  programs.fzf = { 
      enable = true;
      enableFishIntegration = true;
      colors = {
        bg = "#24273a";     
        "bg+" = "#363a4f";  
        spinner = "#f4dbd6"; 
        hl = "#ed8796";      
        fg = "#cad3f5";     
        header = "#ed8796"; 
        info = "#c6a0f6";   
        pointer = "#f4dbd6"; 
        marker = "#f4dbd6";  
        "fg+" = "#cad3f5";  
        prompt = "#c6a0f6";  
        "hl+" = "#ed8796";   
      };
      defaultOptions = [
       "--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" 
       "--preview 'cat {}'"
      ];
    };

  programs.neovim = {
    defaultEditor = true;
    enable = true;
    withNodeJs = true; 
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      buf = {
        disabled = true;
      };
      character = {
        success_symbol = "[󰘧](bold green)";
        error_symbol = "[󰘧](bold red)";
      };
      directory = {
        truncate_to_repo = false;
      };
      dotnet = {
        detect_files = [
          "global.json"
          "Directory.Build.props"
          "Directory.Build.targets"
          "Packages.props"
        ];
      };
      lua = {
        symbol = " "; 
      };
      git_branch = {
        symbol = " ";
      };
      package = {
        disabled = true;
      };
    };
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../config/tmux/tmux.conf;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    initExtra = ''
      ${builtins.readFile ../config/zsh/functions.zsh}
      ${builtins.readFile ../config/zsh/opam.zsh}
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "z" ];
      theme = "robbyrussell";
    };
    shellAliases = {
      "c" = "clear";
      "code" = "vim";
      "ks" = "tmux kill-server";
    };
    syntaxHighlighting = {
      enable = true;
    };
  };
}
