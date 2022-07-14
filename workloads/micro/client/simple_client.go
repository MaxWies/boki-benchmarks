package client

import (
	"net/http"
	"time"
)

type SimpleClient struct {
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
