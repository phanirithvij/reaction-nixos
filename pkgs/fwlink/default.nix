{ lib, stdenv, go, makeWrapper }:
stdenv.mkDerivation rec {

  pname = "fwlink";
  version = "unstable-2023-04-13";
  src = ./fwlink.go;

  nativeBuildInputs = [ go ];

  unpackPhase = "cp $src fwlink.go";

  buildPhase = ''
    runHook preBuild

    mkdir ./tmp
    GOCACHE=$(pwd)/tmp go build ./fwlink.go

    runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install ./fwlink $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "A script that symlinks Funkwhale-organised tracks to a tag-organised directory";
    homepage = "https://framagit.org/ppom/nixos";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux;
  };
}
