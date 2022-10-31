{ lib, stdenv, fetchurl, makeDesktopItem, makeWrapper }:
let
  pname = "slskd";
  version = "0.16.27";

  src = fetchurl {
    url = "https://github.com/slskd/slskd/releases/download/${version}/slskd-${version}-linux-x64.zip";
    sha256 = "sha256-78awjXg50xjUYNQZKAnkCgVBxs+OMKfkOPjCqIH+YrY=";
  };

in stdenv.mkDerivation {
  inherit pname src version;

  nativeBuildInputs = [ ];

  # TODO externalize static content
  # TODO
  buildPhase = ''
    runHook preBuild

    mkdir -p $out/lib

    runHook postBuild
    '';

  # TODO
  installPhase = ''
    runHook preInstall

    cp -r src $out/

    runHook postInstall
  '';

  # TODO
  postFixup = ''
    mkdir -p $out/bin
    makeWrapper <EXECUTABLE> $out/bin/${pname} --add-flags "-cp $out/lib application.Main" --chdir $out
    '';

  meta = with lib; {
    description = "A modern client-server application for the Soulseek file sharing network";
    homepage = "https://github.com/slskd/slskd";
    license = licenses.agpl3;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.all;
  };
}
