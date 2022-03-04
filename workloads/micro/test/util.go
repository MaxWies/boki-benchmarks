package test

import (
	"encoding/json"
	"faas-micro/constants"
	"faas-micro/handlers"
	"faas-micro/response"
	"faas-micro/utils"
	"fmt"
	"log"
	"testing"

	"cs.utexas.edu/zjia/faas/types"
)

const (
	testBenchmarkType string = "someTestBenchmark"
	outputDirectory   string = constants.BASE_PATH_ENGINE_BOKI_BENCHMARK + "/" + testBenchmarkType
)

func OperationCall(handler types.FuncHandler, request []byte) (*response.Benchmark, error) {
	contextMock := &ContextMock{}
	result, err := handler.Call(contextMock, request)
	if err != nil {
		return nil, err
	}
	var appendLoopOutput response.Benchmark
	err = json.Unmarshal(result, &appendLoopOutput)
	if err != nil {
		return nil, err
	}
	return &appendLoopOutput, nil
}

func SampleMergeRequest(isAsync bool, function string) ([]byte, error) {
	return json.Marshal(utils.JSONValue{
		"directory": outputDirectory,
		"function":  function,
	})
}

func MergeCall(isAsync bool, encoded []byte, t *testing.T) {
	handler := handlers.NewMergeHandler()
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
	if benchmark.Calls <= 0 {
		t.Error("There seem to be no calls of the function")
	}
	if !benchmark.TimeLog.Valid {
		t.Error("Time Log is invalid")
	}
	fmt.Printf("%s", result)
	_ = result
}

func SampleRequest_AppendLoop() []byte {
	req, _ := json.Marshal(utils.JSONValue{
		"record":                     utils.CreateRecord(1024),
		"loop_duration":              1,
		"latency_bucket_lower":       0,
		"latency_bucket_upper":       3000,
		"latency_bucket_granularity": 10,
		"latency_head_size":          10,
		"latency_tail_size":          10,
		"benchmark_type":             testBenchmarkType,
	})
	return req
}

func SampleRequest_AppendReadLoop() []byte {
	req, _ := json.Marshal(utils.JSONValue{
		"record":                     utils.CreateRecord(1024),
		"read_times":                 2,
		"loop_duration":              1,
		"latency_bucket_lower":       0,
		"latency_bucket_upper":       3000,
		"latency_bucket_granularity": 10,
		"latency_head_size":          10,
		"latency_tail_size":          10,
		"benchmark_type":             testBenchmarkType,
	})
	return req
}
