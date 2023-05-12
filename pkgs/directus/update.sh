#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq moreutils nodejs prefetch-npm-deps

set -xeu

# Update directus with a web api call

last_release() { # owner, repo
	curl -L -s \
		-H "Accept: application/vnd.github+json" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/$1/$2/releases?per_page=1" \
		| jq -r '.[0].name'
}

sdk_version="$(last_release directus sdk)"
directus_version="$(last_release directus directus)"

sqlite_version="$(curl -L -s \
	"https://raw.githubusercontent.com/directus/directus/$directus_version/api/package.json" \
	| jq -r '.optionalDependencies.sqlite3')"

cat package.json \
	| jq '.dependencies.directus = "'$directus_version'" | .dependencies."'@directus/sdk'" = "'$sdk_version'" | .dependencies.sqlite3 = "'$sqlite_version'"' \
	| sponge package.json

tmp="$(mktemp -d)"
here="$(pwd)"

cp "$here/package.json" "$tmp"

cd "$tmp"

npm i

cp -f "$tmp/package-lock.json" "$here"

rm -r "$tmp"

cd "$here"

hash=$(prefetch-npm-deps package-lock.json)

sed -i '/npmDepsHash/s§".*"§"'$hash'"§' default.nix
sed -i '/version =/s/".*"/"'$directus_version'"/' default.nix
