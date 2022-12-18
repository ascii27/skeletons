package main

import (
    "fmt"
    "net/http"
)

func healthcheck(w http.ResponseWriter, req *http.Request) {

    fmt.Fprintf(w, "alive\n")
}

func hello(w http.ResponseWriter, req *http.Request) {

    fmt.Fprintf(w, "hello\n")
}

func main() {

    http.HandleFunc("/health", healthcheck)
    http.HandleFunc("/hello", hello)

    http.ListenAndServe(":8080", nil)
}
