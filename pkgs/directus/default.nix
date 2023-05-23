{
  lib
, buildNpmPackage
, callPackage
, jq
, linkFarm
, pkg-config
, python3
, vips
}:

# update this package with ./update.sh

# an embedded version of vips is included in ./vips
# if there is an npm error on the sharp module, adapt the version
# from https://github.com/lovell/sharp/blob/<VERSION>/package.json → .config.libvips
let
  vips' = callPackage ./vips.nix {};
in buildNpmPackage {
  pname = "directus";
  version = "v10.1.1";

  src = linkFarm "directus-source" [
    { name = "package.json"; path = ./package.json; }
    { name = "package-lock.json"; path = ./package-lock.json; }
  ];

  # Required for sharp dependency
  nativeBuildInputs = [
    python3
    pkg-config
    vips'
  ];

  buildInputs = [
    vips'
  ];

  # Workaround buildNpmPackage.installHook assuming this directory exists
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/node/build-npm-package/hooks/npm-install-hook.sh#L27
  preInstall = ''
    mkdir -p $out/lib/node_modules/$(${jq}/bin/jq --raw-output '.name' package.json)
  '';

  postInstall = ''
    mkdir $out/bin
    ln -s $out/lib/node_modules/directus/node_modules/.bin/directus $out/bin/directus 
    ln -s ${./package.json} $out/lib/package.json
  '';

  npmDepsHash = "sha256-SfjseZLsBVHmjm6gG0joLhMp0fs0HY+7ywdo/HFAfKQ=";

  dontNpmBuild = true;

  meta = with lib; {
    description = "The Modern Data Stack rabbit — Directus is an instant REST+GraphQL API and intuitive no-code data collaboration app for any SQL database";
    homepage = "https://directus.io";
    license = licenses.bsl11;
    maintainers = with maintainers; [ ppom ];
  };
}
