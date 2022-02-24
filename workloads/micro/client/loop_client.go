package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"cs.utexas.edu/zjia/faas-micro/handlers"
)

type HttpResultAppendLoop struct {
	Err              error
	Success          bool
	StatusCode       int
	AppendLoopOutput handlers.AppendLoopResponse
}

type JSONValue = map[string]interface{}

func JsonPostRequest(client *http.Client, url string, request JSONValue) *HttpResultAppendLoop {
	encoded, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("[FATAL] Failed to encode JSON request: %v", err)
	}
	log.Printf("[Info] HTTP Post to url: %s", url)
	resp, err := client.Post(url, "application/json", bytes.NewReader(encoded))
	if err != nil {
		log.Printf("[ERROR] HTTP Post failed: %v", err)
		return &HttpResultAppendLoop{Err: err, Success: false}
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		log.Printf("[ERROR] Non-OK response: %d", resp.StatusCode)
		return &HttpResultAppendLoop{Success: false, StatusCode: resp.StatusCode}
	}

	var appendLoopOutput handlers.AppendLoopResponse
	err = json.NewDecoder(resp.Body).Decode(&appendLoopOutput)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
	}
	log.Printf("[Info] JSON received")

	return &HttpResultAppendLoop{
		StatusCode:       resp.StatusCode,
		AppendLoopOutput: appendLoopOutput,
	}
}

func BuildFunctionUrl(gatewayAddr string, fnName string) string {
	return fmt.Sprintf("http://%s/function/%s", gatewayAddr, fnName)
}

type FaasCall struct {
	FnName string
	Input  JSONValue
	Result *HttpResultAppendLoop
}

type faasWorker struct {
	gateway string
	client  *http.Client
	reqChan chan *FaasCall
	wg      *sync.WaitGroup
	results []*FaasCall
}

func (w *faasWorker) start() {
	defer w.wg.Done()
	for {
		call, more := <-w.reqChan
		if !more {
			break
		}
		url := BuildFunctionUrl(w.gateway, call.FnName)
		call.Result = JsonPostRequest(w.client, url, call.Input)
		call.Input = nil
		w.results = append(w.results, call)
	}
}

type FaasClient struct {
	reqChan chan *FaasCall
	workers []*faasWorker
	wg      *sync.WaitGroup
}

func NewFaasClient(faasGateway string, concurrency int) *FaasClient {
	reqChan := make(chan *FaasCall, concurrency)
	workers := make([]*faasWorker, concurrency)
	wg := &sync.WaitGroup{}
	wg.Add(concurrency)
	for i := 0; i < concurrency; i++ {
		worker := &faasWorker{
			gateway: faasGateway,
			client: &http.Client{
				Transport: &http.Transport{
					MaxConnsPerHost: 1,
					MaxIdleConns:    1,
					IdleConnTimeout: 30 * time.Second,
				},
				Timeout: 4 * time.Second,
			},
			reqChan: reqChan,
			wg:      wg,
			results: make([]*FaasCall, 0, 1),
		}
		go worker.start()
		workers[i] = worker
	}
	return &FaasClient{
		reqChan: reqChan,
		workers: workers,
		wg:      wg,
	}
}

func (c *FaasClient) AddJsonFnCall(fnName string, input JSONValue) {
	call := &FaasCall{
		FnName: fnName,
		Input:  input,
		Result: nil,
	}
	c.reqChan <- call
}

func (c *FaasClient) WaitForResults() []*FaasCall {
	close(c.reqChan)
	c.wg.Wait()
	results := make([]*FaasCall, 0)
	for _, worker := range c.workers {
		results = append(results, worker.results...)
	}
	return results
}
