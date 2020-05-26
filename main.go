package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"runtime"
)

const (
	linuxFileDir   = "/home/"
	windowsFileDir = "C:\\Users\\Public\\"
)

var fileDir string

func init() {
	if runtime.GOOS == "linux" {
		fileDir = linuxFileDir
	}
	if runtime.GOOS == "windows" {
		fileDir = windowsFileDir
	}
}

func main() {
	http.Handle("/", http.FileServer(http.Dir(fileDir)))
	http.HandleFunc("/upload", uploadHandler)
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println(err)
	}
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	reader, err := r.MultipartReader()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	for {
		part, err := reader.NextPart()
		if err == io.EOF {
			break
		}

		fmt.Printf("FileName=[%s], FormName=[%s]\n", part.FileName(), part.FormName())
		if part.FileName() == "" { // this is FormData
			data, _ := ioutil.ReadAll(part)
			fmt.Printf("FormData=[%s]\n", string(data))
		} else { // This is FileData
			dst, _ := os.Create(fileDir + part.FileName())
			defer dst.Close()
			io.Copy(dst, part)
		}
	}
	w.Write([]byte("success"))
	w.WriteHeader(200)
}
