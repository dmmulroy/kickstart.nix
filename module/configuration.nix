{ username }: { pkgs, ...}:
{
  # add more system settings here
  nix = {
    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = [ "flakes" "nix-command" ];
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "@wheel" ];
      warn-dirty = false;
    };
  };

  services.nix-daemon.enable = true;

  environment.loginShell = "${pkgs.fish}/bin/fish";

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.fish;
  };
 
  # programs.zsh.enable = true;
  programs.fish.enable = true;
}
