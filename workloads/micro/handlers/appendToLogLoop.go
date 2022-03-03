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
type AppendLoopInput struct {
	Record                   []byte `json:"record"`
	LoopDuration             int    `json:"loop_duration"`
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
	success := float64(0)
	calls := uint(0)
	avg_latency := float64(0)
	bucketLatency := utils.CreateBucket(parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity)
	headLatency := utils.PriorityQueueMin{
		Items: []int64{},
		Limit: parsedInput.LatencyHeadSize,
	}
	tailLatency := utils.PriorityQueueMax{
		Items: []int64{},
		Limit: parsedInput.LatencyTailSize,
	}
	startTime := time.Now()
	endTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}

		// call append
		log.Print("[INFO] Append start")
		appendBegin := time.Now()
		output, err := operations.Append(ctx, h.env, &operations.AppendInput{Record: parsedInput.Record})
		appendDuration := time.Since(appendBegin).Microseconds()
		log.Printf("[INFO] Append needed %d microseconds\n", appendDuration)
		endTime = time.Now()

		calls++
		if err == nil {
			success++
			avg_latency = ((success-1)/success)*avg_latency + (1/success)*float64(appendDuration)
			bucketLatency.Insert(appendDuration)
			headLatency.Add(appendDuration)
			tailLatency.Add(appendDuration)
		}
		_ = output
	}
	throughput := float64(success) / float64(time.Since(startTime).Seconds())

	benchmark := &response.Benchmark{
		Id:                  uuid.New(),
		Success:             uint(success),
		Calls:               calls,
		Throughput:          throughput,
		AverageLatency:      float64(avg_latency),
		BucketLatency:       *bucketLatency,
		HeadLatency:         headLatency,
		TailLatency:         tailLatency,
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
			Benchmark:  "Append to Log",
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
