{
  stdenv,
  lib,
  fetchFromGitHub,
  jre8,
  gradle,
  fd,
}:
# Error:
# Build fails like in this issue: https://github.com/streamaserver/streama/issues/1114

# Update:
# sudo $(nix-build -E "with import <nixos> {}; (callPackage ./default.nix {}).mitmCache.updateScript" --no-out-link)
let
  self = stdenv.mkDerivation (finalAttrs: {
    pname = "streama";
    version = "1.10.5";

    src = fetchFromGitHub {
      owner = "streamaserver";
      repo = "streama";
      rev = "v${finalAttrs.version}";
      hash = "sha256-NCJhPmUSOhNRsbgtcG5fHLkJsn0pvby12h3WS/ZVXWo=";
    };

    patches = [
      ./bigger-subtitles.patch
    ];

    nativeBuildInputs = [ gradle ];

    # if the package has dependencies, mitmCache must be set
    mitmCache = gradle.fetchDeps {
      pkg = self;
      data = ./deps.json;
    };

    # this is required for using mitm-cache on Darwin
    __darwinAllowLocalNetworking = true;

    gradleFlags = [ "-Dfile.encoding=utf-8" ];

    # defaults to "assemble"
    gradleBuildTask = "shadowJar";

    # will run the gradleCheckTask (defaults to "test")
    doCheck = true;

    installPhase = ''
      ${fd} --color always
      mkdir -p $out/{bin,share/streama}
      cp build/libs/streama.jar $out/share/streama

      makeWrapper ${jre8}/bin/java $out/bin/streama \
        --add-flags "-jar $out/share/streama/streama.jar"
    '';

    meta = {
      sourceProvenance = with lib.sourceTypes; [
        fromSource
        binaryBytecode # mitm cache
      ];
      homepage = "https://github.com/streamaserver/streama";
      description = "Self hosted streaming media server";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ ppom ];
    };
  });
in
self
