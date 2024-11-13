{ lib, stdenv, go }:
stdenv.mkDerivation {

  pname = "convertd";
  version = "unstable-2024-11-13";
  src = ./convertd.go;

  nativeBuildInputs = [ go ];

  unpackPhase = "cp $src convertd.go";

  buildPhase = ''
    runHook preBuild

    mkdir ./tmp
    GOCACHE=$(pwd)/tmp go build ./convertd.go

    runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install ./convertd $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "A script that handles a queue of video conversion tasks";
    homepage = "https://framagit.org/ppom/nixos";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux;
  };
}
