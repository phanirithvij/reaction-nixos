#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq moreutils nodejs prefetch-npm-deps

set -xeu

tmp="$(mktemp -d)"
here="$(pwd)"

cp "$here/package.json" "$tmp"

cd "$tmp"

npm update --save '@directus/sdk' 'directus' 'sqlite3'
npm i

cp -f "$tmp/package-lock.json" "$here"

cd "$here"

rm -r "$tmp"

hash=$(prefetch-npm-deps package-lock.json)

sed -i '/npmDepsHash/s>".*">"'$hash'">' default.nix
sed -i '/version =/s/".*"/"'$directus_version'"/' default.nix
