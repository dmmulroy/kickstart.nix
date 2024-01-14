{ pkgs, ... }:

{
  # https://mipmip.github.io/home-manager-option-search/

  # add home-manager user settings here
  home.packages = with pkgs; [ git neovim ];
  home.stateVersion = "23.11";

  programs.direnv = { 
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true; 
    };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../config/tmux/tmux.conf;
  };
}
