{stdenvNoCC}:
stdenvNoCC.mkDerivation rec {
  pname = "mono-lisa-dev";
  version = "2.012";
  src = builtins.fetchGit {
    url = "git@github.com:dmmulroy/mono-lisa.git";
    rev = "763f84582715cdda44a178f8f328ea32776de17c";
    ref = "refs/tags/v${version}";
  };

  installPhase = ''
    install -Dm444 *.ttf -t $out/share/fonts
  '';
}
