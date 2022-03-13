package client

import (
	"bytes"
	"encoding/json"
	"faas-micro/operations"
	"fmt"
	"log"
	"net/http"
)

type HttpResultLoop struct {
	Err        error
	Success    bool
	StatusCode int
	Benchmark  operations.Benchmark
}

type CallSync struct {
}

func (callSync *CallSync) JsonPostRequest(client *http.Client, url string, request JSONValue) *HttpResult {
	encoded, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("[FATAL] Failed to encode JSON request: %v", err)
	}
	log.Printf("[INFO] HTTP Post to url: %s", url)
	resp, err := client.Post(url, "application/json", bytes.NewReader(encoded))
	if err != nil {
		log.Printf("[ERROR] HTTP Post failed: %v", err)
		return &HttpResult{Err: err, Success: false}
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		log.Printf("[ERROR] Non-OK response: %d", resp.StatusCode)
		return &HttpResult{Success: false, StatusCode: resp.StatusCode}
	}

	var benchmark operations.Benchmark
	err = json.NewDecoder(resp.Body).Decode(&benchmark)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
		return &HttpResult{Err: err, Success: false, StatusCode: resp.StatusCode}
	}
	log.Printf("[INFO] HTTP response received")

	return &HttpResult{
		StatusCode: resp.StatusCode,
		Success:    true,
		Result:     benchmark,
	}
}

func (callSync *CallSync) BuildFunctionUrl(gatewayAddr string, fnName string) string {
	return fmt.Sprintf("http://%s/function/%s", gatewayAddr, fnName)
}
