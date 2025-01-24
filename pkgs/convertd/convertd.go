package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"strings"
	"time"
)

const PRESET = "HQ 720p30 Surround"

var logDir, outDir, todoDir string

func main() {
	runtimeDir := os.Getenv("RUNTIME_DIRECTORY")
	if runtimeDir == "" {
		println("$RUNTIME_DIRECTORY must be set")
		os.Exit(1)
	}
	logDir = path.Join(runtimeDir, "log")
	outDir = path.Join(runtimeDir, "out")
	todoDir = path.Join(runtimeDir, "todo")

	for _, dir := range []string{logDir, outDir, todoDir} {
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			println("could not create directory: ", err)
			os.Exit(1)
		}
	}

	for {
		already_no_todo := false
		var err error
		var tasks []fs.DirEntry

		for {
			tasks, err = os.ReadDir(todoDir)
			if err != nil {
				println("could not read directory: ", err)
				os.Exit(1)
			}

			if len(tasks) > 0 {
				break
			}

			if !already_no_todo {
				println("waiting for order in ", todoDir)
				already_no_todo = true
			}
			time.Sleep(5 * time.Second)
		}

		handleTask(tasks[0].Name())
	}
}

func handleTask(taskName string) {
	logPath := path.Join(logDir, taskName) + ".log"

	err := _handleTask(taskName, logPath)

	if err != nil {
		message := "Error while converting " + taskName + ": " + err.Error()

		println(message)
		err := os.WriteFile(logPath+".ko", []byte(message), 0644)
		if err != nil {
			println("could not write ko file for task: ", taskName)
			os.Exit(1)
		}
	}
}

func _handleTask(taskName, logPath string) error {

	// Remove task from task directory
	defer func() {
		err := os.Rename(path.Join(todoDir, taskName), path.Join(logDir, taskName))
		if err != nil {
			println("could not move task: ", taskName)
			os.Exit(1)
		}
	}()

	// Retrieve task
	taskBytes, err := os.ReadFile(path.Join(todoDir, taskName))
	if err != nil {
		println("could not read task file: ", err)
		os.Exit(1)
	}
	inputFile := strings.TrimSpace(string(taskBytes))

	outBase := path.Base(strings.TrimSuffix(inputFile, path.Ext(inputFile)))

	outBase = path.Join(outDir, outBase)
	outPath := outBase
	// If output file already exists, add a number to it
	if _, err = os.Stat(outPath + ".mp4"); err == nil {
		var newOutPath string
		i := 0
		for err == nil {
			i++
			newOutPath = fmt.Sprintf("%s.%v", outPath, i)
			_, err = os.Stat(newOutPath + ".mp4")
		}
		outPath = newOutPath
	}
	outPath += ".mp4"

	// If input file is unreadable, stop
	if _, err = os.Stat(inputFile); err != nil {
		return err
	}

	// Create log file
	logFile, err := os.Create(logPath)
	if err != nil {
		println("could not write log file for task: ", taskName)
		os.Exit(1)
	}
	defer logFile.Close()
	logFile.WriteString(fmt.Sprintln("Converting", inputFile, " to ", outPath))

	// Video conversion
	{
		cmd := exec.Command(
			"HandBrakeCLI",
			"--preset", PRESET,
			"--optimize",
			"--rate", "24", "--pfr",
			"--quality", "23",
			"--turbo",
			"--audio-lang-list", "eng,fra,ita,spa",
			"--subtitle-lang-list", "fra,eng,ita,spa",
			"-i", inputFile,
			"-o", outPath)

		cmd.Stdout = logFile
		cmd.Stderr = logFile

		err = cmd.Run()
		if err != nil {
			return err
		}
	}

	// Subtitles extraction
	{
		ffmpegArgs := []string{"-i", inputFile}

		ffData, err := runFFprobe(inputFile)
		if err != nil {
			return err
		}

		subtitleFound := false
		for _, stream := range ffData.Streams {
			if stream.CodecName == "subrip" && stream.Disposition.Forced == 0 {
				subtitleFound = true
				ffmpegArgs = append(ffmpegArgs,
					"-map",
					"0:"+string(stream.Index),
					fmt.Sprintf("%s.%v.%s.srt", outBase, stream.Index, stream.Tags.Language),
				)
			}
		}

		if subtitleFound {
			cmd := exec.Command("ffmpeg", ffmpegArgs...)

			cmd.Stdout = logFile
			cmd.Stderr = logFile

			err = cmd.Run()
			if err != nil {
				return err
			}
		}
	}

	return nil
}

type FFprobe struct {
	Streams []Stream
}

type Stream struct {
	Index       int
	CodecName   string
	Disposition struct {
		Forced int
	}
	Tags struct {
		Language string
	}
}

func runFFprobe(inputFile string) (FFprobe, error) {
	cmd := exec.Command(
		"ffprobe",
		"-v", "quiet",
		"-print_format", "json",
		"-show_format",
		"-show_streams",
		inputFile)

	var ffprobeData FFprobe
	var stdout bytes.Buffer
	cmd.Stdout = &stdout

	err := cmd.Run()
	if err != nil {
		return ffprobeData, err
	}

	err = json.Unmarshal(stdout.Bytes(), &ffprobeData)
	return ffprobeData, err
}
