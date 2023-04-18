{ lib, stdenv
, fetchFromGitHub
, fetchurl
, unzip
, dotnetCorePackages
, buildDotnetModule
, mono
}:
let
  pname = "slskd";
  version = "0.17.5";

  # TODO build this via npm
  wwwroot = stdenv.mkDerivation {
    inherit version;
    pname = "${pname}-wwwroot";

    src = fetchurl {
      url = "https://github.com/slskd/slskd/releases/download/${version}/slskd-${version}-linux-x64.zip";
      sha256 = "sha256-QYGu2kwZJPMXeSYcE2HpC44RvSOl4MUgNp1Z+gTvrck=";
    };

    nativeBuildInputs = [ unzip ];

    unpackPhase = ''
      unzip -q $src
    '';

    sourceRoot = "./wwwroot";

    installPhase = ''
      cp -r . $out
    '';
  };

in buildDotnetModule {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "slskd";
    repo = "slskd";
    rev = version;
    sha256 = "sha256-iIM29ZI3M9etbw4yzin+4f4cGHIt5qjIl7uzsTUCBc4=";
  };

  runtimeDeps = [ mono ];

  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_7_0;

  projectFile = "slskd.sln";

  nugetDeps = ./deps.nix;

  postInstall = ''
    rm $out/lib/slskd/wwwroot/.gitkeep
    rmdir $out/lib/slskd/wwwroot
    ln -s ${wwwroot} $out/lib/slskd/wwwroot
  '';

  meta = with lib; {
    description = "A modern client-server application for the Soulseek file sharing network";
    homepage = "https://github.com/slskd/slskd";
    license = licenses.agpl3;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux;
  };
}
