{ lib, buildNpmPackage, linkFarm, vips, pkg-config, python3, jq }:

# UPDATE
# Update the dependencies of ./package.json:
# - @directus/sdk → https://www.npmjs.com/package/@directus/sdk
# - directus → https://github.com/directus/directus/releases/
# - sqlite3 → https://github.com/directus/directus/blob/v9.22.1/api/package.json → optionalDependencies

buildNpmPackage {
  pname = "directus";
  version = "9.21.2";

  src = linkFarm "directus-source" [
    { name = "package.json"; path = ./package.json; }
    { name = "package-lock.json"; path = ./package-lock.json; }
  ];

  # Required for sharp dependency
  nativeBuildInputs = [
    python3
    pkg-config
    vips
  ];

  buildInputs = [
    vips
  ];

  # Workaround buildNpmPackage.installHook assuming this directory exists
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/node/build-npm-package/hooks/npm-install-hook.sh#L27
  preInstall = ''
    mkdir -p $out/lib/node_modules/$(${jq}/bin/jq --raw-output '.name' package.json)
  '';

  postInstall = ''
    mkdir $out/bin
    ln -s $out/lib/node_modules/directus/node_modules/.bin/directus $out/bin/directus 
  '';

  npmDepsHash = "sha256-vlOHcAbjP/XmMQDDlps1PoDvGHEYm0vUPjlrfCzGEfY=";

  dontNpmBuild = true;

  meta = with lib; {
    description = "The Modern Data Stack rabbit — Directus is an instant REST+GraphQL API and intuitive no-code data collaboration app for any SQL database";
    homepage = "https://directus.io";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ppom ];
  };
}
