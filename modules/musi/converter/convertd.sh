set +o nounset
set +o errexit

die() {
	echo "$1" >&2
	exit 1
}

# shellcheck disable=SC2016
test -n "$RUNTIME_DIRECTORY" || die '$RUNTIME_DIRECTORY must be set'

LOG_DIRECTORY="$RUNTIME_DIRECTORY/log"
OUT_DIRECTORY="$RUNTIME_DIRECTORY/out"
TODO_DIRECTORY="$RUNTIME_DIRECTORY/todo"

mkdir -p $LOG_DIRECTORY $OUT_DIRECTORY $TODO_DIRECTORY || die "Could not create runtime directories"

ALREADY_NO_TODO=0
PRESET="HQ 720p30 Surround"

while true
do
	# Retrieve next file to convert
	shopt -s nullglob dotglob
	unset -v TASK

	for TASK in "$TODO_DIRECTORY"/*; do
		[ -f "$TASK" ] && break
		unset -v TASK
	done

	if test -z "$TASK"
	then
		if test $ALREADY_NO_TODO -eq 0
		then
			echo -n "Nothing in $TODO_DIRECTORY, retrying in 1min"
			ALREADY_NO_TODO=1
		else
			echo -n .
		fi
		sleep 5s
		continue
	fi
	ALREADY_NO_TODO=0

	# Test file
	FILE="$(cat "$TASK")"

	NAME="$(basename "${FILE%.*}")"
        NUM=1
        while test -e "$OUT_DIRECTORY/$NAME.$NUM.mp4"
        do
            NUM=$((NUM + 1))
        done

	DEST="$OUT_DIRECTORY/$NAME.$NUM.mp4" 
	unset NUM NAME

	LOG_FILE="$LOG_DIRECTORY/$(basename "$TASK")-$(basename "$DEST").log"

	if test ! -f "$FILE"
	then
		echo "File $FILE doesn't exist!" | tee "$LOG_FILE.ko"
		rm "$TASK"
		continue
	fi

	echo "Converting $FILE to $DEST" | tee "$LOG_FILE"

	HandBrakeCLI \
		--preset "$PRESET" \
		--optimize \
		--rate 24 --pfr \
		--quality 23 \
		--two-pass --turbo \
		--subtitle-lang-list fra,eng,ita,spa \
		-i "$FILE" \
		-o "$DEST" |& tee "$LOG_FILE"

        if test $? -ne 0
        then
                echo "Error converting $FILE" | tee "$LOG_FILE.ko"
        fi

	mv "$TASK" "$LOG_DIRECTORY/$(basename "$TASK")"
done
