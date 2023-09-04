package main

import (
	"errors"
	"fmt"
	"os"
	"path"
	"regexp"
	"time"
)

func x(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	if len(os.Args) < 2 {
		x(errors.New("no argument provided"))
	}
	dir := os.Args[1]

	entries, err := os.ReadDir(dir)
	x(err)

	today := time.Now().Format(time.DateOnly)
	template := regexp.MustCompile("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")

	for _, file := range entries {
		if !file.IsDir() {
			x(fmt.Errorf("entry %v is not a directory", file.Name()))
		} else if !template.MatchString(file.Name()) {
			x(fmt.Errorf("entry %v doesn't match xxxx-xx-xx", file.Name()))
		} else if file.Name() < today {
			fmt.Printf("removing %v...\n", file.Name())
			err = os.RemoveAll(path.Join(dir, file.Name()))
			x(err)
		} else {
			break
		}
	}
}
