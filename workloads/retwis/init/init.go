package main

import (
	"flag"
	"log"

	"cs.utexas.edu/zjia/faas-retwis/utils"
)

var FLAGS_faas_gateway string

func init() {
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
}

func retwis_init() {
	client := utils.NewSimpleClient(FLAGS_faas_gateway)
	result := client.Call("RetwisInit", utils.JSONValue{})
	if result.StatusCode != 200 {
		log.Print("[ERROR] Init request failed")
	} else {
		log.Print("[INFO] Init successful")
	}
}
func main() {
	flag.Parse()
	retwis_init()
}
