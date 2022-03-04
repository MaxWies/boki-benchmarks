package test

import (
	"faas-micro/constants"
	"faas-micro/handlers"
	"faas-micro/utils"
	"sync"
	"testing"
)

func TestAppendReadLoop_Sync(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectory)
	_, err := OperationCall(
		handlers.NewAppendReadLoopHandler(&EnvironmentMock{}, false),
		SampleRequest_AppendReadLoop())
	if err != nil {
		t.Errorf("Operation failed: %v", err)
	}
}

func TestAppendReadLoop_Async_MultipleFunctions(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectory)
	var wg sync.WaitGroup
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func(t *testing.T) {
			defer wg.Done()
			OperationCall(
				handlers.NewAppendReadLoopHandler(&EnvironmentMock{}, true),
				SampleRequest_AppendReadLoop())
		}(t)
	}
	wg.Wait()
}

func TestAppendReadLoop_Async_MultipleFunctions_MergeResults(t *testing.T) {
	TestAppendReadLoop_Async_MultipleFunctions(t)
	encoded, _ := SampleMergeRequest(true, constants.FunctionAppendAndReadLoopAsync)
	MergeCall(true, encoded, t)
}
