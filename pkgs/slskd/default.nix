{ lib, stdenv
, buildNpmPackage
, fetchFromGitHub
, fetchurl
, unzip
, dotnetCorePackages
, buildDotnetModule
, mono
, nodejs-18_x
}:
let
  pname = "slskd";
  version = "0.17.5";

  src = fetchFromGitHub {
    owner = "slskd";
    repo = "slskd";
    rev = version;
    sha256 = "sha256-iIM29ZI3M9etbw4yzin+4f4cGHIt5qjIl7uzsTUCBc4=";
  };

  buildNpmPackage' = buildNpmPackage.override { nodejs = nodejs-18_x; };

  wwwroot = buildNpmPackage' {
    pname = "slskd-web";
    version = version;
    src = "${src}/src/web";
    patches = [ ./package-lock.patch ];
    npmFlags = [ "--legacy-peer-deps" ];
    npmDepsHash = "sha256-vURi36ebdJQofhBlElIH5m6T1b8tsVGAzXCiDYUcSww=";
    installPhase = ''
      cp -r build $out
    '';
    meta = {
      license = lib.licenses.agpl3;
    };
  };

in buildDotnetModule {
  inherit pname version src;

  runtimeDeps = [ mono ];

  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_7_0;

  projectFile = "slskd.sln";

  testProjectFile = "tests/slskd.Tests.Unit/slskd.Tests.Unit.csproj";
  doCheck = true;

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
