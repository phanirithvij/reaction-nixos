{
  stdenv,
  lib,
  jre8,
  bash,
  makeWrapper,
  fetchurl,
}:

# Maintainer's note: waiting for an easy solution to
# [this issue](https://github.com/NixOS/nixpkgs/issues/17342)
# before compiling from source

let
  version = "1.10.3";
  jarName = "streama-${version}.jar";
in
stdenv.mkDerivation {
  pname = "streama";
  inherit version;

  src = fetchurl {
    url = "https://github.com/streamaserver/streama/releases/download/v${version}/${jarName}";
    sha256 = "0pb1mg5x2vpv6s5bxpzwkpssq6f2623iwnjdc3irpqw3b2ssr6cx";
  };

  buildInputs = [
    jre8
    makeWrapper
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${jre8}/bin/java $out/bin/streama \
      --add-flags "-jar $src"
  '';

  meta = with lib; {
    homepage = "https://github.com/streamaserver/streama";
    description = "Self hosted streaming media server";
    license = licenses.mit;
    maintainers = with maintainers; [ ppom ];
  };
}
