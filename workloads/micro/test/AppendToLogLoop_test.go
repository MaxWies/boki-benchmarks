package test

import (
	"encoding/json"
	"log"
	"sync"
	"testing"

	"faas-micro/handlers"
	"faas-micro/utils"
)

const (
	outputDirectoryPath string = "/tmp/boki/output/benchmarks/AppendToLogLoopAsync"
)

func SampleRequest() utils.JSONValue {
	return utils.JSONValue{
		"record":                     utils.CreateRecord(1024),
		"loop_duration":              1,
		"latency_bucket_lower":       0,
		"latency_bucket_upper":       3000,
		"latency_bucket_granularity": 10,
	}
}

func MergeRequest() utils.JSONValue {
	return utils.JSONValue{
		"Directory":    outputDirectoryPath,
		"MergableType": "AppendLoopResponse",
	}
}

func AppendCall(isAsync bool, t *testing.T) {
	environmentMock := &EnvironmentMock{}
	handler := handlers.NewAppendLoopHandler(environmentMock, isAsync)
	request := SampleRequest()
	encoded, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("[FATAL] Failed to encode JSON request: %v", err)
	}
	contextMock := &ContextMock{}
	result, err := handler.Call(contextMock, encoded)
	if err != nil {
		t.Error("Error is not nil")
	}

	var appendLoopOutput handlers.AppendLoopResponse
	err = json.Unmarshal(result, &appendLoopOutput)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
	}
	_ = result
}

func MergeCall(t *testing.T) {
	handler := handlers.NewMergeHandler()
	request := MergeRequest()
	encoded, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("[FATAL] Failed to encode JSON request: %v", err)
	}
	contextMock := &ContextMock{}
	result, err := handler.Call(contextMock, encoded)
	if err != nil {
		t.Error("Error is not nil")
	}
	var appendLoopResponse handlers.AppendLoopResponse
	err = json.Unmarshal(result, &appendLoopResponse)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
	}
	_ = result
}

func TestAppendToLogLoopSync(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectoryPath)
	AppendCall(false, t)
}

func TestAppendToLogLoopAsync(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectoryPath)
	AppendCall(true, t)
}

func TestAppendToLogLoopAsync_MultipleFunctions(t *testing.T) {
	err := utils.CreateOutputDirectory(outputDirectoryPath)
	if err != nil {
		t.Error("Error is not nil")
	}
	var wg sync.WaitGroup
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func(t *testing.T) {
			defer wg.Done()
			AppendCall(true, t)
		}(t)
	}
	wg.Wait()
}

func TestAppendToLogLoopAsync_MultipleFunctions_MergeResults(t *testing.T) {
	TestAppendToLogLoopAsync_MultipleFunctions(t)
	MergeCall(t)
}
