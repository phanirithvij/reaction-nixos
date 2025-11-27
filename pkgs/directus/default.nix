{
  lib,
  buildNpmPackage,
  callPackage,
  pkg-config,
  python3,
  # if there is an npm error on the sharp module, you should adapt the vips version
  # from https://github.com/lovell/sharp/blob/<VERSION>/package.json → .config.libvips
  # vips,
  writeScriptBin,
  nodejs_22,
}:
let
  nodejs = nodejs_22;
  vips' = callPackage ./vips.nix { };
  # The original script is just a wrapper to app/cli/run
  # that checks always for the latest version.
  # We don't want to be constantly remminded we are some version behind
  directus-bin = writeScriptBin "directus" ''
    #!${lib.getExe nodejs}
    import('@directus/api/cli/run.js');
  '';
in
buildNpmPackage rec {
  pname = "directus";
  version = "11.12.0";

  src = builtins.filterSource (
    path: _:
    let
      basename = builtins.baseNameOf path;
    in
    lib.hasSuffix ".json" basename
  ) ./.;

  npmDepsHash = "sha256-7LbRN2/laJBU2R3jvKWj1uF5sNhbg+G0L+fqWF9maGY=";

  dontNpmBuild = true;

  inherit nodejs;

  # Required for sharp dependency
  nativeBuildInputs = [
    python3
    pkg-config
    vips'
  ];

  buildInputs = [
    vips'
  ];

  postInstall = ''
    mkdir $out/bin
    cp ${directus-bin}/bin/directus $out/lib/node_modules/directus/node_modules/.bin/
    ln -s $out/lib/node_modules/directus/node_modules/.bin/directus $out/bin/directus
    ln -s $src/package.json $out/lib/package.json
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "The Modern Data Stack rabbit — Directus is an instant REST+GraphQL API and intuitive no-code data collaboration app for any SQL database";
    homepage = "https://directus.io";
    changelog = "https://github.com/directus/directus/releases/tag/v${version}";
    license = licenses.bsl11;
    mainProgram = "directus";
    maintainers = with maintainers; [ ppom ];
  };
}
