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
	"faas-micro/response"

	"cs.utexas.edu/zjia/faas/types"
	"github.com/google/uuid"
)

// Input from client
type AppendLoopInput struct {
	Record                   []byte `json:"record"`
	LoopDuration             int    `json:"loop_duration"`
	SnapshotInterval         int    `json:"snapshot_interval"`
	LatencyBucketLower       int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper       int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity int64  `json:"latency_bucket_granularity"`
	LatencyHeadSize          int    `json:"latency_head_size"`
	LatencyTailSize          int    `json:"latency_tail_size"`
	BenchmarkType            string `json:"benchmark_type"`
}

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
	parsedInput := &AppendLoopInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	log.Printf("[INFO] Run loop for %d seconds. Latency bucket granularity is %d. Size of a record is %d", parsedInput.LoopDuration, parsedInput.LatencyBucketGranularity, len(parsedInput.Record))
	if parsedInput.SnapshotInterval < 1 {
		// no snapshots
		parsedInput.SnapshotInterval = parsedInput.LoopDuration + 1000
	}
	success := 0
	calls := uint(0)
	appendOperations := make([]*response.Operation, 0)
	appendOperation := response.CreateInitialOperationResult("append", parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity, parsedInput.LatencyHeadSize, parsedInput.LatencyTailSize)
	appendOperations = append(appendOperations, appendOperation)
	startTime := time.Now()
	endTime := time.Now()
	snapshotCounter := 1
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}
		if time.Since(startTime) > time.Duration(parsedInput.SnapshotInterval*snapshotCounter)*time.Second {
			appendOperation = response.CreateInitialOperationResult("append", parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity, parsedInput.LatencyHeadSize, parsedInput.LatencyTailSize)
			appendOperations = append(appendOperations, appendOperation)
			snapshotCounter++

		}
		appendBegin := time.Now()
		output, err := operations.Append(ctx, h.env, &operations.AppendInput{Record: parsedInput.Record})
		appendDuration := time.Since(appendBegin).Microseconds()
		endTime = time.Now()

		if err == nil {
			appendOperation.AddSuccess(appendDuration, time.Since(startTime).Microseconds())
			success++
		} else {
			appendOperation.AddFailure()
		}
		calls++
		_ = output
	}
	throughput := float64(success) / float64(time.Since(startTime).Seconds())

	benchmark := &response.Benchmark{
		Id:                  uuid.New(),
		Success:             uint(success),
		Calls:               calls,
		Throughput:          throughput,
		Operations:          appendOperations,
		ConcurrentFunctions: 1,
		TimeLog: response.TimeLog{
			LoopDuration: parsedInput.LoopDuration,
			StartTime:    startTime.UnixNano(),
			EndTime:      endTime.UnixNano(),
			MinStartTime: startTime.UnixNano(),
			MaxStartTime: startTime.UnixNano(),
			MinEndTime:   endTime.UnixNano(),
			MaxEndTime:   endTime.UnixNano(),
			Valid:        true,
		},
		Description: response.Description{
			Benchmark:  parsedInput.BenchmarkType,
			Throughput: "[Op/s] Operations per second",
			Latency:    "[microsec] Operation latency",
			RecordSize: fmt.Sprintf("[byte] %d", len((parsedInput.Record))),
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
		return json.Marshal(&response.BenchmarkAsync{})
	} else {
		return json.Marshal(benchmark)
	}
}
