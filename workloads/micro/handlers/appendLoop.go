package handlers

import (
	"context"
	"encoding/json"
	"faas-micro/constants"
	"faas-micro/operations"
	"fmt"
	"log"
	"path"
	"time"

	"cs.utexas.edu/zjia/faas/types"
	"github.com/google/uuid"
)

type appendLoopHandler struct {
	kind    string
	env     types.Environment
	isAsync bool
}

func NewAppendLoopHandler(env types.Environment, isAsync bool) types.FuncHandler {
	return &appendLoopHandler{
		kind:    "append",
		env:     env,
		isAsync: isAsync,
	}
}

func (h *appendLoopHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	log.Printf("[INFO] Call AppendLoopHandler. Async: %v", h.isAsync)
	parsedInput := &operations.OperationInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	if parsedInput.SnapshotInterval < 1 {
		// no snapshots
		parsedInput.SnapshotInterval = parsedInput.LoopDuration + 1000
	}
	if parsedInput.ConcurrentOperations < 1 {
		parsedInput.ConcurrentOperations = 1
	}
	parsedInput.LogParameters()
	snapshotCounter := 0
	operationHandler := operations.NewAppendOperationHandler(h.env, parsedInput)

	go operationHandler.OperationFinished()

	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}
		if time.Since(startTime) > time.Duration(parsedInput.SnapshotInterval*(snapshotCounter+1))*time.Second {
			operationHandler.WaitForOperationsEnd()
			snapshotCounter++
			operationHandler.NewSnapshot(operations.CreateAppendBenchmark(parsedInput))
		}
		operationHandler.WaitForFreeGoRoutine()
		operationHandler.StartOperation()
		go operationHandler.AppendCall(ctx, startTime, parsedInput.Record)
	}
	operationHandler.WaitForOperationsEnd()
	operationHandler.CloseChannels()
	endTime := time.Now()

	calls := uint(0)
	success := uint(0)
	operationBenchmarks := make([]*operations.OperationBenchmark, 0)
	for i := 0; i <= snapshotCounter; i++ {
		ob := *operationHandler.GetOperationBenchmarks(i)
		operationBenchmarks = append(operationBenchmarks, ob...)
		for j := range ob {
			calls += ob[j].Calls
			success += ob[j].Success
		}
	}

	throughput := float64(success) / float64(time.Since(startTime).Seconds())

	benchmark := &operations.Benchmark{
		Id:                  uuid.New(),
		Success:             uint(success),
		Calls:               uint(calls),
		Throughput:          throughput,
		Operations:          operationBenchmarks,
		ConcurrentFunctions: 1,
		TimeLog: operations.TimeLog{
			LoopDuration: parsedInput.LoopDuration,
			StartTime:    startTime.UnixNano(),
			EndTime:      endTime.UnixNano(),
			MinStartTime: startTime.UnixNano(),
			MaxStartTime: startTime.UnixNano(),
			MinEndTime:   endTime.UnixNano(),
			MaxEndTime:   endTime.UnixNano(),
			Valid:        true,
		},
		Description: operations.Description{
			Benchmark:        parsedInput.BenchmarkType,
			Throughput:       "[Op/s] Operations per second",
			Latency:          "[microsec] Operation latency",
			RecordSize:       fmt.Sprintf("[byte] %d", len((parsedInput.Record))),
			SnapshotInterval: parsedInput.SnapshotInterval,
		},
	}

	log.Printf("[INFO] Loop finished. %d calls successful from %d total calls", int(success), calls)

	if h.isAsync {
		fileDirectory := path.Join(constants.BASE_PATH_ENGINE_BOKI_BENCHMARK, parsedInput.BenchmarkType)
		fileName := constants.FunctionAppendLoopAsync + "_" + benchmark.Id.String()
		err = benchmark.WriteToFile(fileDirectory, fileName)
		if err != nil {
			return nil, err
		}
		return json.Marshal(&operations.BenchmarkAsync{})
	} else {
		return json.Marshal(benchmark)
	}
}
