{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "pussh";
  version = "unstable-2025-02-12";

  src = fetchFromGitHub {
    owner = "bearstech";
    repo = "pussh";
    rev = "576669b5c6ee4e833d66e42a8cb0dbe188449277";
    hash = "sha256-4uA6I3TJqQFR0x+XxN+hFVzEv+aDrAoWpH7cLFtGqDA=";
  };

  installPhase = ''
    mkdir -p $out/{bin,share/man/man1}
    install -m755 pussh $out/bin
    install -m644 pussh.1 $out/share/man/man1/
  '';

  meta = {
    description = "Parallel SSH, batch and command line oriented";
    homepage = "https://github.com/bearstech/pussh/tree/master";
    changelog = "https://github.com/bearstech/pussh/blob/${src.rev}/NEWS";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ppom ];
    mainProgram = "pussh";
    platforms = lib.platforms.all;
  };
}
