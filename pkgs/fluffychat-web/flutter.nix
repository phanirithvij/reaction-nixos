{ lib
, callPackage
, llvmPackages_13
, flutter
, jq
}:

# absolutely no mac support for now

{ pubGetScript ? "flutter pub get"
, flutterBuildFlags ? [ ]
, runtimeDependencies ? [ ]
, customPackageOverrides ? { }
, autoDepsList ? false
, depsListFile ? null
, vendorHash ? ""
, pubspecLockFile ? null
, nativeBuildInputs ? [ ]
, preUnpack ? ""
, postFixup ? ""
, ...
}@args:
let
  flutterSetupScript = ''
    export HOME="$NIX_BUILD_TOP"
    flutter config --no-analytics &>/dev/null # mute first-run
    # flutter config --enable-linux-desktop >/dev/null
  '';

  deps = callPackage /nix/var/nix/profiles/per-user/root/channels/nixos/pkgs/build-support/dart/fetch-dart-deps { dart = flutter; } {
    sdkSetupScript = flutterSetupScript;
    inherit pubGetScript vendorHash pubspecLockFile;
    buildDrvArgs = args;
  };

  baseDerivation = llvmPackages_13.stdenv.mkDerivation (finalAttrs: args // {
    inherit flutterBuildFlags runtimeDependencies;

    outputs = [ "out" ];

    nativeBuildInputs = [
      deps
      flutter
      jq
    ] ++ nativeBuildInputs;

    preUnpack = ''
      ${lib.optionalString (!autoDepsList) ''
        if ! { [ '${lib.boolToString (depsListFile != null)}' = 'true' ] ${lib.optionalString (depsListFile != null) "&& cmp -s <(jq -Sc . '${depsListFile}') <(jq -Sc . '${finalAttrs.passthru.depsListFile}')"}; }; then
          echo 1>&2 -e '\nThe dependency list file was either not given or differs from the expected result.' \
                      '\nPlease choose one of the following solutions:' \
                      '\n - Duplicate the following file and pass it to the depsListFile argument.' \
                      '\n   ${finalAttrs.passthru.depsListFile}' \
                      '\n - Set autoDepsList to true (not supported by Hydra or permitted in Nixpkgs)'.
          exit 1
        fi
      ''}

      ${preUnpack}
    '';

    configurePhase = ''
      runHook preConfigure

      ${flutterSetupScript}

      runHook postConfigure
    '';

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

    passthru = {
      inherit (deps) depsListFile;
    };
  });

  packageOverrideRepository = (callPackage /nix/var/nix/profiles/per-user/root/channels/nixos/pkgs/development/compilers/flutter/package-overrides { }) // customPackageOverrides;
  productPackages = builtins.filter (package: package.kind != "dev")
    (if autoDepsList
    then lib.importJSON deps.depsListFile
    else
      if depsListFile == null
      then [ ]
      else lib.importJSON depsListFile);
in
builtins.foldl'
  (prev: package:
  if packageOverrideRepository ? ${package.name}
  then
    prev.overrideAttrs
      (packageOverrideRepository.${package.name} {
        inherit (package)
          name
          version
          kind
          source
          dependencies;
      })
  else prev)
  baseDerivation
  productPackages
