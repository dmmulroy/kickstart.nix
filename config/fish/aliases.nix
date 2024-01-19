{
  c = "clear";
  code = "vim";
  dwc = ''darwin-rebuild check --flake ".#aarch64"'';
  dwb = ''darwin-rebuild switch --flake ".#aarch64"'';
  grep = "grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}";
  ks = "tmux kill-server";
  node-env = "nix-shell -p nodejs_21 bun typescript eslint_d prettierd --command fish";
} 
