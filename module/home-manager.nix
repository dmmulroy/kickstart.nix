{ pkgs, config, ... }:

{
  # https://mipmip.github.io/home-manager-option-search/

  home.packages = with pkgs; [ 
    bun
    fd
    git
    prettierd
    rectangle
    ripgrep
    tree
    wget
  ];

  home.stateVersion = "23.11";

  programs.direnv = { 
      enable = true;
      enableZshIntegration = true;
      # This gets enabled by default when enabling programs.fish
      # enableFishIntegration = true;
      nix-direnv.enable = true; 
    };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      eval "$(/opt/homebrew/bin/brew shellenv)"
      
      ${builtins.readFile ../config/fish/catppuccin_macchiato_theme.fish}
    '';
    functions = import ../config/fish/functions.nix;
    plugins = [
      { 
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }

      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
    shellAliases = import ../config/fish/aliases.nix;
  };

  programs.fzf = { 
      enable = true;
      enableZshIntegration = true;
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

  xdg.configFile = {
    ghostty = { 
      source = config.lib.file.mkOutOfStoreSymlink ../config/ghostty; 
      recursive = true;
    }; 
  };

  xdg.configFile = {
    nvim = { 
      source = config.lib.file.mkOutOfStoreSymlink ../config/nvim; 
      recursive = true;
    }; 
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraLuaConfig = ''
      require('user')
    '';
    withNodeJs = true; 
    withPython3 = true;
    withRuby = true;
    vimdiffAlias = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
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
      "dwc" = ''darwin-rebuild check --flake ".#aarch64"'';
      "dwb" = ''darwin-rebuild switch --flake ".#aarch64"'';
      "ks" = "tmux kill-server";
      "node-env" = "nix-shell -p nodejs_21 bun typescript eslint_d prettierd --command zsh";
    };
    syntaxHighlighting = {
      enable = true;
    };
  };
}
