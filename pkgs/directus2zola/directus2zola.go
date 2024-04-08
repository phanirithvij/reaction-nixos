// This programs waits for build command with HTTP with a specific route for each project configured.
// Then it performs the following actions:
// - Clone the git repository and ensure it is up-to-date
// - Execute the user script and parse its output as JSON
// - Recreate the content directory and populate it with user script's output
// - Build with zola
// - Push with rsync
//
// This could easily made more agnostic by removing git_url, push_url, ssh_key_file
// and replacing those with arrays of PreScript/PostScript commands, but I don't need it for now.
//
// Configuration example:
//
//	{
//		"state_directory": "/var/lib/directus2zola",
//		"ssh_key_file": "/var/secrets/ssh_key",
//		"port": 2048,
//		"projects": [
//			{
//				"name": "example.fr",
//				"git_url": "git.example.fr/example.fr",
//				"push_url": "example.fr:/var/www/example.fr/",
//				"script": ["echo", "{}"]
//			}
//		],
//	}
//
// Script output example:
//
//	{
//		"paths": [
//			{
//				"path": "_index.md",
//				"type": "text",
//				"header": {
//					"title": "My Title",
//					"date": "2024-03-24",
//				},
//				"header_extra": {
//					"awesome": true
//				},
//				"body": "This is the content of the article",
//			},
//			{
//				"path": "../data.json",
//				"type": "raw",
//				"raw": "{\"value\": 1}",
//			},
//			{
//				"path": "article/asset.png",
//				"type": "download",
//				"url": "data.example.fr/assets/123456.png",
//			}
//		],
//	}
//
// - path is relative to zola's content directory. mandatory.
// - type is one of text, raw, download. mandatory.
// - when type is download: url is the HTTP GET to make. mandatory.
// - when type is text:     header, header_extra and body all are optional. omitted means empty.
// - when type is raw:      raw is optional. omitted means empty.

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path"
	"reflect"
	"runtime"
	"strings"
	"sync"
	"time"
)

type Configuration struct {
	StateDirectory string    `json:"state_directory"`
	SSHKeyFile     string    `json:"ssh_key_file"`
	Port           int       `json:"port"`
	Projects       []Project `json:"projects"`
}

type Project struct {
	Name       string   `json:"name"`
	GitUrl     string   `json:"git_url"`
	PushUrl    string   `json:"push_url"`
	SSHKeyFile string   `json:"ssh_key_file"`
	Script     []string `json:"script"`
	ScriptOnly bool     `json:"script_only"`

	gitDirectory string

	lock                     sync.Mutex
	isBuilding, wantsToBuild bool
}

func Fatal(arg ...any) {
	fmt.Println(arg...)
	os.Exit(1)
}

func main() {
	conf := parseConfiguration()
	testRequirements(conf)
	for i := range conf.Projects {
		conf.Projects[i].init()
	}
	fmt.Println("INFO  server ready to accept incoming requests")
	Fatal(http.ListenAndServe(fmt.Sprintf(":%v", conf.Port), nil))
}

func parseConfiguration() *Configuration {
	if len(os.Args) != 2 {
		fmt.Println("Exactly one argument must be given: the configuration file")
	}
	data, err := os.Open(os.Args[1])
	if err != nil {
		Fatal("Failed to read configuration file: ", err)
	}
	var conf Configuration
	err = json.NewDecoder(data).Decode(&conf)
	if err != nil {
		Fatal("Failed to parse configuration file: ", err)
	}
	// Test configuration validity
	if len(conf.Projects) == 0 {
		Fatal("No projects")
	}
	if conf.Port == 0 {
		Fatal("Item port is not defined")
	}
	// Defaults values
	if conf.StateDirectory == "" {
		conf.StateDirectory = "."
	}
	// Test projects validity
	names := make(map[string]bool)
	for i := range conf.Projects {
		project := &conf.Projects[i]
		// Those variables must be set
		if project.Name == "" {
			Fatal("A project has no name.")
		}
		if project.GitUrl == "" {
			Fatal("Project", project.Name, "has no git_url")
		}
		if project.PushUrl == "" {
			Fatal("Project", project.Name, "has no push_url")
		}
		if len(project.Script) == 0 {
			Fatal("Project", project.Name, "has no data_command")
		}
		// Name uniqueness
		if names[project.Name] {
			Fatal("Two projects with name", project.Name)
		}
		names[project.Name] = true

		// Default values
		if project.SSHKeyFile == "" {
			if conf.SSHKeyFile == "" {
				Fatal("Project", project.Name, "has no ssh_key_file and main configuration don't either")
			}
			project.SSHKeyFile = conf.SSHKeyFile
		}
		project.gitDirectory = path.Join(conf.StateDirectory, project.Name)
	}
	return &conf
}

func testRequirements(conf *Configuration) {
	// Test that all commands are in PATH
	commands := []string{"git", "rsync", "ssh", "zola"}
	for i := range conf.Projects {
		commands = append(commands, conf.Projects[i].Script[0])
	}
	for _, executable := range commands {
		_, err := exec.LookPath(executable)
		if err != nil {
			Fatal("executable", executable, "not found in PATH")
		}
	}
	for i := range conf.Projects {
		// Test that SSH keys are accessible
		_, err := os.Stat(conf.Projects[i].SSHKeyFile)
		if err != nil {
			Fatal("could not read ssh key: ", err)
		}
	}
	// Test that StateDirectory is writable
	testfilepath := path.Join(conf.StateDirectory, "test.txt")
	file, err := os.Create(testfilepath)
	if err != nil {
		Fatal("could not write to StateDirectory: ", err)
	}
	file.Close()
	err = os.Remove(testfilepath)
	if err != nil {
		Fatal("could not write to StateDirectory: ", err)
	}
}

func (p *Project) init() {
	http.HandleFunc("/"+p.Name, func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "building")
		p.lock.Lock()
		if p.isBuilding {
			p.wantsToBuild = true
		} else {
			go p.doBuild()
		}
		p.lock.Unlock()
	})
}

func (p *Project) doBuild() {
	p.lock.Lock()
	p.isBuilding = true
	p.wantsToBuild = false
	p.lock.Unlock()

	start := time.Now()
	p.Infof("requested to build")
	var finished string
	if p.build() {
		finished = "finished"
	} else {
		finished = "failed"
	}
	elapsed := time.Now().Sub(start).Milliseconds()
	p.Infof("%v to build in %v seconds", finished, float64(elapsed)/1000.0)

	p.lock.Lock()
	p.isBuilding = false
	if p.wantsToBuild {
		p.lock.Unlock()

		p.doBuild()
	} else {
		p.lock.Unlock()
	}
}

type UserData struct {
	Paths []UserPath `json:"paths"`
}

type UserPath struct {
	Path string `json:"path"`
	Type string `json:"type"`
	// Type: text
	Header      map[string]any `json:"header"`
	HeaderExtra map[string]any `json:"header_extra"`
	Body        string         `json:"body"`
	// Type: raw
	Raw string `json:"raw"`
	// Type: download
	URL string `json:"url"`
}

func (p *Project) build() bool {
	var err error

	if !p.ScriptOnly {
		// Clean & Pull
		_, err = os.Stat(p.gitDirectory)
		if err != nil {
			if !p.exec(func(cmd *exec.Cmd) { cmd.Dir = "" }, "git", "clone", "-q", p.GitUrl, p.gitDirectory) {
				return false
			}
		}
		if !p.exec(nil, "git", "clean", "-f", "-q") {
			return false
		}
		if !p.exec(nil, "git", "reset", "--hard", "-q") {
			return false
		}
		if !p.exec(nil, "git", "pull", "-q", "--ff-only") {
			return false
		}
	}

	var wg sync.WaitGroup
	var isErr bool

	// Recreate content directory
	wg.Add(1)
	go func() {
		defer wg.Done()
		p.Infof("recreate content directory")
		contentDirectory := path.Join(p.gitDirectory, "content")
		err = os.RemoveAll(contentDirectory)
		if err != nil {
			p.Errorf("Could not empty directory 'content': %v", err)
			isErr = true
			return
		}
		err = os.Mkdir(contentDirectory, 0755)
		if err != nil {
			p.Errorf("Could not recreate directory 'content': %v", err)
			isErr = true
			return
		}
	}()

	// Run user script
	var data UserData
	r, w := io.Pipe()
	go func() {
		if !p.exec(func(cmd *exec.Cmd) { cmd.Stdout = w }, p.Script[0], p.Script[1:]...) {
			isErr = true
			return
		}
	}()
	wg.Add(1)
	go func() {
		defer wg.Done()
		err = json.NewDecoder(r).Decode(&data)
		if err != nil {
			p.Errorf("Could not decode data from script: %v", err)
			isErr = true
			return
		}
		p.Infof("user script returned %v elements", len(data.Paths))
	}()

	wg.Wait()
	if isErr {
		return false
	}

	p.Infof("populating content directory")
	// Create paths
	pathsC := make(chan UserPath)
	for i := 0; i < runtime.NumCPU(); i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			var pData UserPath
			ok := true
			for ok {
				select {
				case pData, ok = <-pathsC:
					if ok && !isErr {
						if !p.mkPath(pData) {
							isErr = true
						}
					}
				}
			}
		}()
	}
	for _, pathData := range data.Paths {
		pathsC <- pathData
	}
	close(pathsC)

	wg.Wait()
	if isErr {
		return false
	}

	if !p.ScriptOnly {
		// zola build
		ok := p.exec(func(cmd *exec.Cmd) { cmd.Stdout = nil }, "zola", "build")
		if !ok {
			return false
		}

		// rsync
		ok = p.exec(nil, "rsync", "-az", "--delete", "--rsh=ssh -i "+p.SSHKeyFile, "./public/", p.PushUrl)
		if !ok {
			return false
		}
	}

	return true
}

func (p *Project) Infof(format string, arg ...any) {
	fmt.Printf("INFO  %v: "+format+"\n", append([]any{p.Name}, arg...)...)
}

func (p *Project) Errorf(format string, arg ...any) {
	fmt.Printf("ERROR %v: "+format+"\n", append([]any{p.Name}, arg...)...)
}

func (p *Project) exec(customize func(cmd *exec.Cmd), command string, arg ...string) bool {
	p.Infof("%v %v", command, arg[0])
	cmd := exec.Command(command, arg...)
	cmd.Dir = p.gitDirectory
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if customize != nil {
		customize(cmd)
	}
	err := cmd.Run()
	if err != nil {
		p.Errorf("'%v %v' failed: %v", command, arg[0], err)
		return false
	}
	return true
}

func (p *Project) mkPath(pData UserPath) bool {
	if pData.Path == "" {
		p.Errorf("path is empty: %#v", pData)
		return false
	}
	fullPath := path.Join(p.gitDirectory, "content", pData.Path)
	err := os.MkdirAll(path.Dir(fullPath), 0755)
	if err != nil {
		p.Errorf("could not create directory %v", path.Dir(fullPath))
		return false
	}
	file, err := os.Create(fullPath)
	if err != nil {
		p.Errorf("could not create file %v: %v", fullPath, err)
		return false
	}
	defer file.Close()

	errmsg := func(err error) bool {
		if err != nil {
			p.Errorf("could not write to file: %v", err)
			return true
		}
		return false
	}
	switch pData.Type {
	case "text":
		var buffer strings.Builder

		buffer.WriteString("+++\n")
		p.writeHeader(&buffer, pData.Header)
		buffer.WriteString("[extra]\n")
		p.writeHeader(&buffer, pData.HeaderExtra)
		buffer.WriteString("+++\n")
		buffer.WriteString(pData.Body)

		_, err := fmt.Fprint(file, buffer.String())
		if errmsg(err) {
			return false
		}
	case "raw":
		_, err := fmt.Fprint(file, pData.Raw)
		if errmsg(err) {
			return false
		}
	case "download":
		response, err := http.Get(pData.URL)
		if err != nil {
			p.Errorf("could not download url %v: %v", pData.URL, err)
			return false
		}
		defer response.Body.Close()
		if response.StatusCode < 200 || response.StatusCode > 299 {
			p.Errorf("invalid http code while downloading url %v: %v", pData.URL, response.StatusCode)
			return false
		}

		_, err = io.Copy(file, response.Body)
		if errmsg(err) {
			return false
		}
	default:
		p.Errorf("unrecognised type of path %v: '%v'", pData.Path, pData.Type)
		return false
	}
	return true
}

func (p *Project) writeHeader(w *strings.Builder, header map[string]any) {
	for key, value := range header {
		var format string
		valueType := reflect.TypeOf(value)
		if valueType != nil {
			switch valueType.Kind() {
			case reflect.String:
				format = "%v = \"\"\"%v\"\"\"\n"
			default:
				format = "%v = %v\n"
			}
			fmt.Fprintf(w, format, key, value)
		}
	}
}
