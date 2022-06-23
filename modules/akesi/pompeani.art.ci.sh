VERSION="$1"

# Must exist
BUILD_DIR="/var/lib/art/build-$VERSION"
OUTPUT_DIR="/var/www/pompeani.art-$VERSION"

REPO_URL="https://framagit.org/ppom/pompeani.art"

REPO_DIR="$(basename "$REPO_URL")"

if test "$VERSION" = "test"
then
	BASE_URL="https://test.pompeani.art"
else
	BASE_URL="https://pompeani.art"
fi

cd "$BUILD_DIR"

test -d "$REPO_DIR" || git clone "$REPO_URL" "$REPO_DIR"

cd "$REPO_DIR"
git restore config.toml
git checkout "$VERSION"

git pull

# Generates small.jpg when it doesn't exist or is older than big.jpg
# shellcheck disable=SC2016
fd big.jpg -x bash -c 'test -e "{//}/small.jpg" && test $(stat -c %Y -- "{}") -lt $(stat -c %Y "{//}/small.jpg") || convert -resize "600x1200>" "{}" "{//}/small.jpg"'

sed -i 's#^base_url.*#base_url = "'"$BASE_URL"'"#' config.toml

zola build

if test $? -ne 0
then
	echo BUILD FAILED
	exit 1
fi

rsync -av --delete public/* "$OUTPUT_DIR"

if test "$VERSION" = "test"
then
	echo "User-agent: *" > "$OUTPUT_DIR/robots.txt"
	echo "Disallow: /"  >> "$OUTPUT_DIR/robots.txt"
fi

