package test

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"testing"

	"faas-micro/constants"
	"faas-micro/handlers"
	"faas-micro/response"
	"faas-micro/utils"
)

const (
	outputDirectoryPath string = constants.BASE_PATH_ENGINE_BOKI_BENCHMARK + "/" + "append-throughput"
)

func SampleRequest() utils.JSONValue {
	return utils.JSONValue{
		"record":                     utils.CreateRecord(1024),
		"loop_duration":              1,
		"latency_bucket_lower":       0,
		"latency_bucket_upper":       3000,
		"latency_bucket_granularity": 10,
		"latency_head_size":          10,
		"latency_tail_size":          10,
		"benchmark_type":             constants.BenchmarkAppendThroughput,
	}
}

func MergeRequest(isAsync bool) utils.JSONValue {
	function := constants.FunctionAppendLoop
	if isAsync {
		function = constants.FunctionAppendLoopAsync
	}
	return utils.JSONValue{
		"directory": outputDirectoryPath,
		"function":  function,
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

	var appendLoopOutput response.Benchmark
	err = json.Unmarshal(result, &appendLoopOutput)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
	}
	_ = result
}

func MergeCall(isAsync bool, t *testing.T) {
	handler := handlers.NewMergeHandler()
	request := MergeRequest(isAsync)
	encoded, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("[FATAL] Failed to encode JSON request: %v", err)
	}
	contextMock := &ContextMock{}
	result, err := handler.Call(contextMock, encoded)
	if err != nil {
		t.Error("Error is not nil")
	}
	var benchmark response.Benchmark
	err = json.Unmarshal(result, &benchmark)
	if err != nil {
		log.Fatalf("[FATAL] Failed to decode JSON response: %v", err)
	}
	if !benchmark.TimeLog.Valid {
		t.Error("Time Log is invalid")
	}
	fmt.Printf("%s", result)
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
	MergeCall(true, t)
}
