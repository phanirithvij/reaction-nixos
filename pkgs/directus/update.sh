#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq moreutils nodejs prefetch-npm-deps
set -eou pipefail

tmpDir="$(mktemp -d)"

cp package.json "$tmpDir"

pushd "$tmpDir"
npm update --save
npm i
popd

cp -f "$tmpDir/package.json" "$tmpDir/package-lock.json" .

# Remove this line:
# "rollup": "^2.63.0"
sed -i '/"\^2.63.0"/d' ./package-lock.json

npmDepsHash=$(prefetch-npm-deps package-lock.json)
directusVersion="$(jq -r '.dependencies.directus' < "$tmpDir/package.json" | tr -d '^')"

sed -i '/npmDepsHash/s>".*">"'"$npmDepsHash"'">' default.nix
sed -i '/version =/s/".*"/"'"$directusVersion"'"/' default.nix

rm -r "$tmpDir"
