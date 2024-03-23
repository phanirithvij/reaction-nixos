{ go, stdenv }:
stdenv.mkDerivation {
  pname = "directus2zola";
  version = "1";
  src = ./directus2zola.go;
  nativeBuildInputs = [ go ];
  dontUnpack = true;
  buildPhase = ''
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH="$TMPDIR/go"
    go build -o ./directus2zola $src
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./directus2zola $out/bin/
  '';
}
