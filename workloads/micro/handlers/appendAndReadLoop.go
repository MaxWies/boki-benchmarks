package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"path"
	"time"

	"faas-micro/constants"
	"faas-micro/operations"

	"cs.utexas.edu/zjia/faas/types"
	"github.com/google/uuid"
)

type appendReadLoopHandler struct {
	kind    string
	env     types.Environment
	isAsync bool
}

func NewAppendReadLoopHandler(env types.Environment, isAsync bool) types.FuncHandler {
	return &appendReadLoopHandler{
		kind:    "appendAndRead",
		env:     env,
		isAsync: isAsync,
	}
}

func (h *appendReadLoopHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	log.Printf("[INFO] Call AppendReadLoopHandler. Async: %v", h.isAsync)
	parsedInput := &operations.OperationInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	if parsedInput.ConcurrentOperations < 1 {
		parsedInput.ConcurrentOperations = 1
	}
	if parsedInput.SnapshotInterval < 1 {
		// no snapshots
		parsedInput.SnapshotInterval = parsedInput.LoopDuration + 1000
	}
	parsedInput.LogParameters()

	snapshotCounter := 0
	operationHandler := operations.NewAppendAndReadOperationHandler(h.env, parsedInput)

	go operationHandler.OperationFinished()

	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}
		operationHandler.WaitForFreeGoRoutine()
		operationHandler.StartOperation()
		go operationHandler.AppendAndReadCall(ctx, startTime, parsedInput.Record, parsedInput.ReadTimes, parsedInput.ReadDirection, parsedInput.UseTags)
	}
	operationHandler.WaitForOperationsEnd()
	operationHandler.CloseChannels()
	endTime := time.Now()

	log.Printf("[INFO] Loop finished")

	if !parsedInput.StatisticsAtContainer {
		return json.Marshal(&operations.BenchmarkAsync{})
	}

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
		Success:             success,
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
			Benchmark:        fmt.Sprintf("Append and Read %d times from Log", parsedInput.ReadTimes),
			Throughput:       "[Op/s] Operations per second",
			Latency:          "[microsec] Operation latency",
			RecordSize:       len(parsedInput.Record),
			SnapshotInterval: parsedInput.SnapshotInterval,
		},
	}

	log.Printf("[INFO] %d calls successful from %d total calls", int(success), calls)

	if h.isAsync {
		fileDirectory := path.Join(constants.BASE_PATH_SLOG_ENGINE_BENCHMARK, parsedInput.BenchmarkType)
		fileName := constants.FunctionAppendAndReadLoopAsync + "_" + benchmark.Id.String()
		err = benchmark.WriteToFile(fileDirectory, fileName)
		if err != nil {
			return nil, err
		}
		return json.Marshal(&operations.BenchmarkAsync{})
	} else {
		return json.Marshal(benchmark)
	}
}
