package test

import (
	"sync"
	"testing"

	"faas-micro/constants"
	"faas-micro/handlers"
	"faas-micro/utils"
)

func Test_AppendToLogLoop_Sync(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectory)
	_, err := OperationCall(
		handlers.NewAppendLoopHandler(&EnvironmentMock{}, false),
		SampleRequest_AppendLoop())
	if err != nil {
		t.Errorf("Operation failed: %v", err)
	}
}

func Test_AppendToLogLoop_Async(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectory)
	_, err := OperationCall(
		handlers.NewAppendLoopHandler(&EnvironmentMock{}, true),
		SampleRequest_AppendLoop())
	if err != nil {
		t.Errorf("Operation failed: %v", err)
	}
}

func TestAppendToLogLoopAsync_MultipleFunctions(t *testing.T) {
	utils.CreateOutputDirectory(outputDirectory)
	var wg sync.WaitGroup
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func(t *testing.T) {
			defer wg.Done()
			OperationCall(
				handlers.NewAppendLoopHandler(&EnvironmentMock{}, true),
				SampleRequest_AppendLoop())
		}(t)
	}
	wg.Wait()
}

func TestAppendToLogLoopAsync_MultipleFunctions_MergeResults(t *testing.T) {
	TestAppendToLogLoopAsync_MultipleFunctions(t)
	encoded, _ := SampleMergeRequest(true, constants.FunctionAppendLoopAsync)
	MergeCall(true, encoded, t)
}
