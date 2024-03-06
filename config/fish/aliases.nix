{
  c = "clear";
  code = "vim";
  dwc = ''darwin-rebuild check --flake ".#aarch64"'';
  dwb = ''darwin-rebuild switch --flake ".#aarch64"'';
  grep = "grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}";
  ks = "tmux kill-server";
  node-shell = "nix shell nixpkgs#{nodejs_21, typescript, nodePackages.pnpm, bun}";
  opam-shell = "nix shell nixpkgs#opam nixpkgs#dune_3 --system aarch64-darwin";
}
