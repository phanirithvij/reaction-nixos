{ lib, stdenv, go, makeWrapper }:
stdenv.mkDerivation {
  pname = "older.go";
  version = "unstable-2023-09-04";
  src = ./older.go;
  nativeBuildInputs = [ go ];
  unpackPhase = "cp $src older.go";
  buildPhase = ''
    mkdir ./tmp
    GOCACHE=$(pwd)/tmp go build ./older.go
  '';
  installPhase = ''
    mkdir -p $out/bin
    install ./older $out/bin/
  '';
  meta = with lib; {
    description = "A script that deletes to-be-deleted files in a directory";
    homepage = "https://framagit.org/ppom/nixos";
    license = licenses.agpl3;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux;
  };
}
