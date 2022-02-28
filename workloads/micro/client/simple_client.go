package client

import (
	"net/http"
	"time"
)

type SimpleClient struct {
	// reqChan       chan *FaasCall
	// workers       []*faasWorker
	// wg            *sync.WaitGroup
	Gateway       string
	HttpClient    *http.Client
	HttpResults   []*HttpResult
	FaasRequester FaasRequester
}

func NewSimpleClient(faasGateway string, faasRequester FaasRequester) *SimpleClient {
	return &SimpleClient{
		Gateway: faasGateway,
		HttpClient: &http.Client{
			Transport: &http.Transport{
				MaxConnsPerHost: 1,
				MaxIdleConns:    1,
				IdleConnTimeout: 30 * time.Second,
			},
			Timeout: 30 * time.Second,
		},
		HttpResults:   make([]*HttpResult, 0, 1),
		FaasRequester: faasRequester,
	}
}

func (c *SimpleClient) SendRequest(functionName string, input JSONValue) {
	url := c.FaasRequester.BuildFunctionUrl(c.Gateway, functionName)
	httpResult := c.FaasRequester.JsonPostRequest(c.HttpClient, url, input)
	c.HttpResults = append(c.HttpResults, httpResult)
}

// func (c *SimpleClient) AddJsonFnCall(fnName string, input JSONValue) {
// 	call := &FaasCall{
// 		FnName:     fnName,
// 		Input:      input,
// 		HttpResult: nil,
// 	}
// 	c.reqChan <- call
// }

// func (c *SimpleClient) WaitForHttpResults() []*FaasCall {
// 	close(c.reqChan)
// 	c.wg.Wait()
// 	HttpResults := make([]*FaasCall, 0)
// 	for _, worker := range c.workers {
// 		HttpResults = append(HttpResults, worker.HttpResults...)
// 	}
// 	return HttpResults
// }
