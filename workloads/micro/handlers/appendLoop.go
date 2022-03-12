package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"path"
	"sync"
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
	SnapshotInterval         int    `json:"snapshot_interval"`
	LatencyBucketLower       int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper       int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity int64  `json:"latency_bucket_granularity"`
	LatencyHeadSize          int    `json:"latency_head_size"`
	LatencyTailSize          int    `json:"latency_tail_size"`
	BenchmarkType            string `json:"benchmark_type"`
	ConcurrencyOperation     int    `json:"concurrency_operation"`
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

type operationHandler struct {
	env                  types.Environment
	operationCalls       chan *utils.OperationCallItem
	operationBenchmark   *response.Operation
	concurrentGoRoutines chan struct{}
	wg                   *sync.WaitGroup
}

func NewOperationHandler(env types.Environment, input *AppendLoopInput) *operationHandler {
	op := &operationHandler{
		env:                  env,
		operationCalls:       make(chan *utils.OperationCallItem),
		operationBenchmark:   response.CreateInitialOperationResult("append", input.LatencyBucketLower, input.LatencyBucketUpper, input.LatencyBucketGranularity, input.LatencyHeadSize, input.LatencyTailSize),
		concurrentGoRoutines: make(chan struct{}, input.ConcurrencyOperation),
		wg:                   &sync.WaitGroup{},
	}
	for i := 0; i < input.ConcurrencyOperation; i++ {
		op.concurrentGoRoutines <- struct{}{}
	}
	return op
}

func (o *operationHandler) operationCall(opCall func() (*types.LogEntry, error), startTime time.Time, call int64) (*types.LogEntry, error) {
	appendBegin := time.Now()
	output, err := opCall()
	_ = output
	success := false
	if err == nil {
		success = true
	}
	o.operationCalls <- &utils.OperationCallItem{
		Latency:           time.Since(appendBegin).Microseconds(),
		Call:              call,
		Success:           success,
		RelativeTimestamp: time.Since(startTime).Microseconds(),
	}
	return output, err
}

func (o *operationHandler) operationSequence(ctx context.Context, startTime time.Time, call int64, record []byte) {
	o.operationCall(
		func() (*types.LogEntry, error) {
			return operations.Append(ctx, o.env, &operations.AppendInput{Record: record})
		}, startTime, call)
}

func (o *operationHandler) operationResponse() {
	for {
		call, more := <-o.operationCalls
		if !more {
			break
		}
		if call.Success {
			o.operationBenchmark.AddSuccess(call)
		} else {
			o.operationBenchmark.AddFailure()
		}
		o.wg.Done()
		o.concurrentGoRoutines <- struct{}{}
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
	if parsedInput.ConcurrencyOperation < 1 {
		parsedInput.ConcurrencyOperation = 1
	}
	calls := int64(0)

	snapshotCounter := 1

	operationHandlers := make([]*operationHandler, 0)
	operationHandler := NewOperationHandler(h.env, parsedInput)
	operationHandlers = append(operationHandlers, operationHandler)

	go operationHandler.operationResponse()

	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}
		if time.Since(startTime) > time.Duration(parsedInput.SnapshotInterval*snapshotCounter)*time.Second {
			operationHandler.wg.Wait()
			close(operationHandler.operationCalls)
			close(operationHandler.concurrentGoRoutines)
			operationHandler = NewOperationHandler(h.env, parsedInput)
			operationHandlers = append(operationHandlers, operationHandler)
			snapshotCounter++
			go operationHandler.operationResponse()
		}
		<-operationHandler.concurrentGoRoutines
		calls++
		operationHandler.wg.Add(1)
		go operationHandler.operationSequence(ctx, startTime, calls, parsedInput.Record)
	}
	operationHandler.wg.Wait()
	close(operationHandler.operationCalls)
	close(operationHandler.concurrentGoRoutines)
	endTime := time.Now()

	success := uint(0)
	operationBenchmarks := make([]*response.Operation, 0)
	for i := range operationHandlers {
		operationBenchmarks = append(operationBenchmarks, operationHandlers[i].operationBenchmark)
		success += operationHandlers[i].operationBenchmark.Success
	}

	throughput := float64(success) / float64(time.Since(startTime).Seconds())

	benchmark := &response.Benchmark{
		Id:                  uuid.New(),
		Success:             uint(success),
		Calls:               uint(calls),
		Throughput:          throughput,
		Operations:          operationBenchmarks,
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
