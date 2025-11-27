{
  lib,
  flutter,
  fetchFromGitHub,
  buildNpmPackage,
  baseHref ? "/",
  writeText,
}:

assert baseHref == "/" || (builtins.match "^/.*/$" baseHref) != null;

let
  olm = buildNpmPackage {
    version = "fork-unstable-2022-01-31";
    name = "olm-fluffychat";
    src = fetchFromGitHub {
      owner = "famedly";
      repo = "olm";
      rev = "580bc452433aa422d649b3969f56efa2adf1a8a5";
      sha256 = "sha256-TTY0LH1jcRSuNsqCST/Rfe/W1pL8lOEyMLC2aWHqNJI=";
    };
    patches = [
      (writeText "package-lock.json" ''
        diff --git a/bin/pw-stream b/bin/pw-stream
        new file mode 100755
        index 0000000..7a96916
        --- /dev/null
        +++ b/bin/pw-stream
        @@ -0,0 +1,1 @@
        +{ "name": "olm", "version": "0.1", "lockfileVersion": 2, "requires": true, "packages": { "": { "name": "olm", "dependencies": {}}}}
      '')
    ];
  };
  version = "1.13.0";

in
(flutter.buildFlutterApplication {
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
    maintainers = with maintainers; [
      mkg20001
      gilice
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ sourceTypes.fromSource ];
  };
}).overrideAttrs
  (oldAttrs: {
    patches = [
      (writeText "base-href.patch" ''
        diff --git a/web/index.html b/web/index.html
        index 18cecab8..7ebfd612 100644
        --- a/web/index.html
        +++ b/web/index.html
        @@ -11,8 +11,11 @@

             For more details:
             * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
        +
        +    This is a placeholder for base href that will be replaced by the value of
        +    the `--base-href` argument provided to `flutter build`.
           -->
        -  <base href="/">
        +  <base href="$FLUTTER_BASE_HREF">

           <meta charset="UTF-8">
           <meta content="IE=Edge" http-equiv="X-UA-Compatible">
      '')
    ];
    outputs = [ "out" ];

    buildPhase = ''
      runHook preBuild

      doPubGet flutter pub get --offline -v
      flutter build web -v --release --base-href ${baseHref}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mv build/web $out
      cp ${olm} $out/assets/js/package/

      runHook postInstall
    '';

    postFixup = "";
  })
