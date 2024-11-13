package main

import (
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
	taskBytes, err := os.ReadFile(path.Join(todoDir, taskName))
	if err != nil {
		println("could not read task file: ", err)
		os.Exit(1)
	}
	inputFile := string(taskBytes)

	outBase := path.Base(strings.TrimSuffix(inputFile, path.Ext(inputFile)))

	outPath := path.Join(outDir, outBase)
	// If file exists
	if _, err = os.Stat(outPath + ".mp4"); err == nil {
		var newOutPath string
		i := 0
		for err == nil {
			i++
			newOutPath = outPath + "." + string(i) + ".mp4"
			_, err = os.Stat(newOutPath)
		}
		outPath = newOutPath
	}

	logPath := path.Join(logDir, taskName) + ".log"

	if _, err = os.Stat(inputFile); err != nil {
		err = os.WriteFile(logPath+".ko", []byte(fmt.Sprintln("Could not access file: ", err)), 0644)
		if err != nil {
			println("could not write ko file for task: ", taskName)
			os.Exit(1)
		}
		return
	}

	logFile, err := os.Create(logPath)

	if err != nil {
		println("could not write log file for task: ", taskName)
		os.Exit(1)
	}

	defer logFile.Close()

	logFile.WriteString(fmt.Sprintln("Converting", inputFile, " to ", outPath))

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
		err = os.WriteFile(logPath+".ko", []byte(fmt.Sprintln("Error converting ", inputFile)), 0644)
		if err != nil {
			println("could not write ko file for task: ", taskName)
			os.Exit(1)
		}
	}

	err = os.Rename(path.Join(todoDir, taskName), path.Join(logDir, taskName))
	if err != nil {
		println("could not move task: ", taskName)
		os.Exit(1)
	}
}
