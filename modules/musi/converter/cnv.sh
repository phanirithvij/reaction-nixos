set +o nounset

# shellcheck disable=SC2016
test -n "$RUNTIME_DIRECTORY" || die '$RUNTIME_DIRECTORY must be set'

TODO_DIRECTORY="$RUNTIME_DIRECTORY/todo"

BASE="$TODO_DIRECTORY/task-$(date '+%y-%m-%d_%H:%M:%S')"
NUM=1

while test -n "$1"
do
	if test ! -f "$1"
	then
		echo "$1 is not a file!"
		continue
	fi

	realpath "$1" > "$BASE-$NUM-$(basename "$1")"

	NUM=$((NUM + 1))
	shift
done
