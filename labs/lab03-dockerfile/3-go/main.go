package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	host, _ := os.Hostname()
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Witaj z programu w Go! Kontener: %s\n", host)
	})
	fmt.Println("Słucham na :8080")
	http.ListenAndServe(":8080", nil)
}
