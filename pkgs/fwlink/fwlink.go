package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func die(msg ...any) {
	fmt.Println(append([]any{"FATAL"}, msg...))
	os.Exit(1)
}

// Executes a command and channel-send its stdout
func cmdStdout(commandline []string) chan *string {
	lines := make(chan *string)

	go func() {
		cmd := exec.Command(commandline[0], commandline[1:]...)
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			die("couldn't open stdout on command:", err)
		}
		if err := cmd.Start(); err != nil {
			die("couldn't start command:", err)
		}
		defer stdout.Close()

		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			lines <- &line
		}
		close(lines)
	}()

	return lines
}

// Gets a SEPARATOR-separated line and gather data.
// This function is very specific to the SQL command below
// and must be adapted if the SELECT order is changed.
func DirectoriesFilenameSource(line *string) (string, string, string) {
	i := strings.Split(*line, SEPARATOR)

	position := i[3]
	if len(position) == 1 {
		position = "0" + position
	}

	escape := func(s string) string { return strings.ReplaceAll(s, "/", "-") }

	dir1 := escape(i[0])
	dir2 := escape(fmt.Sprintf("%v - %s", i[1], i[2]))

	directories := fmt.Sprintf("%s/%s", dir1, dir2)

	filename := escape(fmt.Sprintf("%v - %s", position, i[4]))

	source := i[5]
	if source == "" {
		source = i[6][7:]
	}

	return directories, filename, source
}

func extension(source string) string {
	lastDot := strings.LastIndex(source, ".")
	if lastDot == -1 {
		fmt.Println("no extension:", source)
		return ".mp3"
	}
	return source[lastDot:]
}

// This must be changed according to your setup.
// Take a look at table columns music_upload.source & music_upload.audio_file
func specialSource(source *string) string {
	if (*source)[0] == '/' {
		return fmt.Sprintf("/data/funkwhale%s", *source)
	}
	return fmt.Sprintf("/data/funkwhale/data/media/%s", *source)
}

var SEPARATOR = "|||"

// On my setup, I can `psql funkwhale` to connect to the database.
// Adapt if needed
var request = []string{"psql", "funkwhale", "-F", SEPARATOR, "-A", "-t", "-c", `
SELECT DISTINCT
ar.name AS artist,
EXTRACT(year FROM al.release_date) AS year, al.title AS album,
t.position, t.title,
u.audio_file, u.source
FROM music_trackactor ta
INNER JOIN music_track t  ON ta.track_id = t.id
INNER JOIN music_upload u ON ta.upload_id = u.id
INNER JOIN music_album al ON t.album_id = al.id
INNER JOIN music_artist ar ON al.artist_id = ar.id
WHERE (u.audio_file <> '' OR u.source LIKE 'file:///%');`}

func main() {
	var err error
	fmt.Println("Starting")

	if len(os.Args) < 2 || len(os.Args[1]) < 1 {
		die("First argument must be the destination dir")
	}
	root := os.Args[1]
	err = os.MkdirAll(root, 0755)
	if err != nil {
		die("mkdir error", err)
	}

	lines := cmdStdout(request)

	var successCount int
	var errorCount int

	for line := range lines {
		directories, filename, source := DirectoriesFilenameSource(line)

		source = specialSource(&source)
		ext := extension(source)

		dir := fmt.Sprintf("%s/%s", root, directories)
		filepath := fmt.Sprintf("%s/%s%s", dir, filename, ext)

		err = os.MkdirAll(dir, 0755)
		if err != nil {
			errorCount++
			continue
		}

		err = os.Link(source, filepath)
		if err != nil {
			errorCount++
			continue
		}

		successCount++
	}

	fmt.Printf("Finished with %v success and %v errors\n", successCount, errorCount)
}
