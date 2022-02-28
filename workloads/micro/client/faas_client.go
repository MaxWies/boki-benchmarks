package client

import (
	"net/http"
	"sync"
	"time"
)

type HttpResult struct {
	Err        error
	Success    bool
	StatusCode int
	Result     interface{}
}

type FaasRequester interface {
	JsonPostRequest(client *http.Client, url string, request JSONValue) *HttpResult
	BuildFunctionUrl(gatewayAddr string, fnName string) string
}

type JSONValue = map[string]interface{}

type FaasCall struct {
	FnName     string
	Input      JSONValue
	HttpResult *HttpResult
}

type faasWorker struct {
	gateway     string
	client      *http.Client
	reqChan     chan *FaasCall
	wg          *sync.WaitGroup
	HttpResults []*FaasCall
}

func (w *faasWorker) start(faasRequester FaasRequester) {
	defer w.wg.Done()
	for {
		call, more := <-w.reqChan
		if !more {
			break
		}
		url := faasRequester.BuildFunctionUrl(w.gateway, call.FnName)
		call.HttpResult = faasRequester.JsonPostRequest(w.client, url, call.Input)
		call.Input = nil
		w.HttpResults = append(w.HttpResults, call)
	}
}

type FaasClient struct {
	reqChan chan *FaasCall
	workers []*faasWorker
	wg      *sync.WaitGroup
}

func NewFaasClient(faasGateway string, concurrency int, faasRequester FaasRequester) *FaasClient {
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
				Timeout: 30 * time.Second,
			},
			reqChan:     reqChan,
			wg:          wg,
			HttpResults: make([]*FaasCall, 0, 1),
		}
		go worker.start(faasRequester)
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
		FnName:     fnName,
		Input:      input,
		HttpResult: nil,
	}
	c.reqChan <- call
}

func (c *FaasClient) WaitForHttpResults() []*FaasCall {
	close(c.reqChan)
	c.wg.Wait()
	HttpResults := make([]*FaasCall, 0)
	for _, worker := range c.workers {
		HttpResults = append(HttpResults, worker.HttpResults...)
	}
	return HttpResults
}
