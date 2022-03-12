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
	"faas-micro/utils"

	"cs.utexas.edu/zjia/faas/types"
	"github.com/google/uuid"
)

// Input from client
type AppendReadLoopInput struct {
	Record                   []byte `json:"record"`
	ReadTimes                int    `json:"read_times"`
	LoopDuration             int    `json:"loop_duration"`
	LatencyBucketLower       int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper       int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity int64  `json:"latency_bucket_granularity"`
	LatencyHeadSize          int    `json:"latency_head_size"`
	LatencyTailSize          int    `json:"latency_tail_size"`
	BenchmarkType            string `json:"benchmark_type"`
}

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
	parsedInput := &AppendReadLoopInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	success := uint(0)
	calls := uint(0)

	appendOperation := response.CreateInitialOperationResult("append", parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity, parsedInput.LatencyHeadSize, parsedInput.LatencyTailSize)
	readOperations := make([]*response.Operation, 0)
	for i := 0; i < parsedInput.ReadTimes; i++ {
		readOperations = append(readOperations, response.CreateInitialOperationResult("read", parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity, parsedInput.LatencyHeadSize, parsedInput.LatencyTailSize))
	}

	log.Printf("[INFO] Run loop for %d seconds. Latency bucket granularity is %d. Size of a record is %d", parsedInput.LoopDuration, parsedInput.LatencyBucketGranularity, len(parsedInput.Record))
	startBenchmarkTime := time.Now()
	for {
		if time.Since(startBenchmarkTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}
		successful := true
		calls++

		// call append
		appendBegin := time.Now()
		uniqueId := h.env.GenerateUniqueID()
		tags := []uint64{uniqueId}
		logEntry, err := operations.Append(ctx, h.env, &operations.AppendInput{Record: parsedInput.Record, Tags: tags})
		appendDuration := time.Since(appendBegin).Microseconds()

		if err == nil {
			appendOperation.AddSuccess(&utils.OperationCallItem{
				Latency:           appendDuration,
				Success:           true,
				RelativeTimestamp: time.Since(startBenchmarkTime).Microseconds(),
			})
		} else {
			successful = false
			// skip reading calls
			for i := range readOperations {
				readOperations[i].AddFailure()
			}
			continue
		}

		// call reads
		for i := range readOperations {
			readBegin := time.Now()
			_, err := operations.ReadNext(ctx, h.env, uniqueId, logEntry.SeqNum)
			readDuration := time.Since(readBegin).Microseconds()
			if err == nil {
				readOperations[i].AddSuccess(&utils.OperationCallItem{
					Latency:           readDuration,
					Success:           true,
					RelativeTimestamp: time.Since(startBenchmarkTime).Microseconds(),
				})
			} else {
				successful = false
			}
		}

		if successful {
			success++
		}
	}
	throughput := float64(success) / float64(time.Since(startBenchmarkTime).Seconds())
	endBenchmarkTime := time.Now()

	benchmark := &response.Benchmark{
		Id:                  uuid.New(),
		Success:             success,
		Calls:               calls,
		Throughput:          throughput,
		Operations:          append([]*response.Operation{appendOperation}, readOperations...),
		ConcurrentFunctions: 1,
		TimeLog: response.TimeLog{
			LoopDuration: parsedInput.LoopDuration,
			StartTime:    startBenchmarkTime.UnixNano(),
			EndTime:      endBenchmarkTime.UnixNano(),
			MinStartTime: startBenchmarkTime.UnixNano(),
			MaxStartTime: startBenchmarkTime.UnixNano(),
			MinEndTime:   endBenchmarkTime.UnixNano(),
			MaxEndTime:   endBenchmarkTime.UnixNano(),
			Valid:        true,
		},
		Description: response.Description{
			Benchmark:  fmt.Sprintf("Append and Read %d times from Log", parsedInput.ReadTimes),
			Throughput: "[Op/s] Operations per second",
			Latency:    "[microsec] Operation latency",
			RecordSize: fmt.Sprintf("[byte] %d", len((parsedInput.Record))),
		},
	}

	log.Printf("[INFO] Loop finished. %d calls successful from %d total calls", int(success), calls)

	if h.isAsync {
		fileDirectory := path.Join(constants.BASE_PATH_ENGINE_BOKI_BENCHMARK, parsedInput.BenchmarkType)
		fileName := constants.FunctionAppendAndReadLoopAsync + "_" + benchmark.Id.String()
		err = benchmark.WriteToFile(fileDirectory, fileName)
		if err != nil {
			return nil, err
		}
		return json.Marshal(&response.BenchmarkAsync{})
	} else {
		return json.Marshal(benchmark)
	}
}
