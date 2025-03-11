set +o nounset

test "$(id -nu)" = "media" || exec sudo -u media "${BASH_SOURCE[0]}" "$@"

# shellcheck disable=SC2016
test -n "$RUNTIME_DIRECTORY" || die '$RUNTIME_DIRECTORY must be set'

TODO_DIRECTORY="$RUNTIME_DIRECTORY/todo"

BASE="$TODO_DIRECTORY/task-$(date '+%y-%m-%d_%H:%M:%S')"
NUM=1
NUMNO="$#"

while test -n "$1"
do
	if test ! -f "$1"
	then
		echo "$1 is not a file!"
		continue
	fi

	realpath "$1" > "$BASE-$(seq -w $NUM $NUMNO | head -n1 )-$(basename "$1").task"

	NUM=$((NUM + 1))
	shift
done
