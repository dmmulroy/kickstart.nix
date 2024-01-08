{ pkgs, ... }:

{
  # https://mipmip.github.io/home-manager-option-search/

  # add home-manager user settings here
  home.packages = with pkgs; [ git neovim ];
  home.stateVersion = "23.11";
}
