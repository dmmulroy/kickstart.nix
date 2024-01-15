{ pkgs, ... }:

{
  # https://mipmip.github.io/home-manager-option-search/

  # add home-manager user settings here
  home.packages = with pkgs; [ git ripgrep neovim ];
  home.stateVersion = "23.11";

  programs.direnv = { 
      enable = true;
      # enableFishIntegration = true;
      # enableZshIntegration = true;
      nix-direnv.enable = true; 
    };

  /* programs.fish = {
    enable = true;
  }; */

  programs.fzf = { 
      enable = true;
      # enableFishIntegration = true;
      # enableZshIntegration = true;
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

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../config/tmux/tmux.conf;
  };
}
