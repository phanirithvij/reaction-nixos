{ lib, stdenv
, fetchurl
, unzip
, zlib
, gcc-unwrapped
, autoPatchelfHook
}:
let
  pname = "slskd";
  version = "0.17.5";

  src = fetchurl {
    url = "https://github.com/slskd/slskd/releases/download/${version}/slskd-${version}-linux-x64.zip";
    sha256 = "sha256-QYGu2kwZJPMXeSYcE2HpC44RvSOl4MUgNp1Z+gTvrck=";
  };

  # TODO really build the app w/ https://nixos.org/manual/nixpkgs/stable/#dotnet

in stdenv.mkDerivation {
  inherit pname src version;

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
    zlib
    gcc-unwrapped.lib
  ];

  unpackPhase = ''
    unzip -q $src
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    cp -r . $out
    mkdir $out/bin
    mv $out/slskd $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern client-server application for the Soulseek file sharing network";
    homepage = "https://github.com/slskd/slskd";
    license = licenses.agpl3;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux;
  };
}
