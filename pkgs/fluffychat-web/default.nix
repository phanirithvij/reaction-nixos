{ lib
, flutter
, fetchFromGitHub
#, olm
}:

let
  # olm' = olm.overrideAttrs(old: {
  #   version = "fork-unstable-2022-01-31";
  #   src = fetchFromGitHub {
  #     owner = "famedly";
  #     repo = "olm";
  #     rev = "580bc452433aa422d649b3969f56efa2adf1a8a5";
  #     sha256 = "sha256-TTY0LH1jcRSuNsqCST/Rfe/W1pL8lOEyMLC2aWHqNJI=";
  #   };
  # });
  version = "1.13.0";

in (flutter.buildFlutterApplication {
  pname = "fluffychat-web";
  inherit version;

  src = fetchFromGitHub {
    owner = "krille-chan";
    repo = "fluffychat";
    rev = "refs/tags/v${version}";
    hash = "sha256-w29Nxs/d0b18jMvWnrRUjEGqY4jGtuEGodg+ncCAaVc=";
  };

  depsListFile = ./deps.json;
  vendorHash = "sha256-Ot96+EF8PgYQmXn0hvIWzN8StuzTgQzakRO3yf7PJAU=";

  meta = with lib; {
    description = "Chat with your friends (matrix web client)";
    homepage = "https://fluffychat.im/";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ mkg20001 gilice ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    sourceProvenance = [ sourceTypes.fromSource ];
  };
}).overrideAttrs (oldAttrs: {
  outputs = [ "out" ];

  buildPhase = ''
      runHook preBuild

      doPubGet flutter pub get --offline -v
      flutter build web -v --release

      runHook postBuild
  '';

  installPhase = ''
      runHook preInstall

      mv build/web $out

      runHook postInstall
  '';

  postFixup = "";
})
