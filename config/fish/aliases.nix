{
  c = "clear";
  code = "vim";
  dwc = ''darwin-rebuild check --flake ".#aarch64"'';
  dwb = ''darwin-rebuild switch --flake ".#aarch64"'';
  grep = "grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}";
  ks = "tmux kill-server";
  node-shell = "nix shell nixpkgs#{nodejs_21, typescript, eslint_d, prettierd, pnpm, bun}";
  kill-opam = "mv ~/.opam ~/_opam";
  revive-opam = "mv ~/_opam ~/.opam";
}
