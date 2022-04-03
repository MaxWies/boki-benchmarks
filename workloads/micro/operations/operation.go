package operations

import (
	"context"
	"faas-micro/constants"
	"faas-micro/utils"
	"fmt"
	"strings"
	"sync"
	"time"

	"cs.utexas.edu/zjia/faas/types"
)

type OperationInput struct {
	Record                   []byte `json:"record"`
	ReadTimes                int    `json:"read_times"`
	UseTags                  bool   `json:"use_tags"`
	LoopDuration             int    `json:"loop_duration"`
	SnapshotInterval         int    `json:"snapshot_interval"`
	LatencyBucketLower       int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper       int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity int64  `json:"latency_bucket_granularity"`
	LatencyHeadSize          int    `json:"latency_head_size"`
	LatencyTailSize          int    `json:"latency_tail_size"`
	BenchmarkType            string `json:"benchmark_type"`
	ConcurrentOperations     int    `json:"concurrent_operations"`
}

func (o *OperationInput) LogParameters() {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Benchmark type: %s\n", o.BenchmarkType))
	sb.WriteString(fmt.Sprintf("Record size: %d\n", len(o.Record)))
	sb.WriteString(fmt.Sprintf("Duration: %d\n", o.LoopDuration))
	sb.WriteString(fmt.Sprintf("Concurrent operations: %d\n", o.ConcurrentOperations))
	sb.WriteString(fmt.Sprintf("Record size: %d\n", len(o.Record)))
}

type OperationHandler struct {
	env                      types.Environment
	operationBenchmarkMatrix *[]*[]*OperationBenchmark
	operationCalls           chan struct{}
	concurrentOperations     chan struct{}
	wg                       *sync.WaitGroup
	snapshot                 int
}

func newOperationHandler(env types.Environment, input *OperationInput, operationBenchmarkMatrix *[]*[]*OperationBenchmark) *OperationHandler {
	op := &OperationHandler{
		env:                      env,
		operationBenchmarkMatrix: operationBenchmarkMatrix,
		operationCalls:           make(chan struct{}),
		concurrentOperations:     make(chan struct{}, input.ConcurrentOperations),
		wg:                       &sync.WaitGroup{},
	}
	for i := 0; i < input.ConcurrentOperations; i++ {
		op.concurrentOperations <- struct{}{}
	}
	return op
}

func CreateAppendBenchmark(input *OperationInput) *[]*OperationBenchmark {
	operationBenchmarks := make([]*OperationBenchmark, 0)
	operationBenchmarks = append(operationBenchmarks, CreateInitialOperationResult("append", input.LatencyBucketLower, input.LatencyBucketUpper, input.LatencyBucketGranularity, input.LatencyHeadSize, input.LatencyTailSize))
	return &operationBenchmarks
}

func CreateAppendAndReadBenchmark(input *OperationInput) *[]*OperationBenchmark {
	operationBenchmarks := make([]*OperationBenchmark, 0)
	operationBenchmarks = append(operationBenchmarks, CreateInitialOperationResult("append", input.LatencyBucketLower, input.LatencyBucketUpper, input.LatencyBucketGranularity, input.LatencyHeadSize, input.LatencyTailSize))
	for i := 0; i < input.ReadTimes; i++ {
		operationBenchmarks = append(operationBenchmarks, CreateInitialOperationResult("read", input.LatencyBucketLower, input.LatencyBucketUpper, input.LatencyBucketGranularity, input.LatencyHeadSize, input.LatencyTailSize))
	}
	return &operationBenchmarks
}

func NewAppendAndReadOperationHandler(env types.Environment, input *OperationInput) *OperationHandler {
	matrix := make([]*[]*OperationBenchmark, 0)
	operationBenchmarks := CreateAppendAndReadBenchmark(input)
	matrix = append(matrix, operationBenchmarks)
	return newOperationHandler(env, input, &matrix)
}

func NewAppendOperationHandler(env types.Environment, input *OperationInput) *OperationHandler {
	matrix := make([]*[]*OperationBenchmark, 0)
	operationBenchmarks := CreateAppendBenchmark(input)
	matrix = append(matrix, operationBenchmarks)
	return newOperationHandler(env, input, &matrix)
}

func (o *OperationHandler) NewSnapshot(operationBenchmarks *[]*OperationBenchmark) {
	o.snapshot += 1
	*o.operationBenchmarkMatrix = append(*o.operationBenchmarkMatrix, operationBenchmarks)
}

func (o *OperationHandler) WaitForFreeGoRoutine() {
	<-o.concurrentOperations
}

func (o *OperationHandler) StartOperation() {
	o.wg.Add(1)
}

func (o *OperationHandler) WaitForOperationsEnd() {
	o.wg.Wait()
}

func (o *OperationHandler) GetOperationBenchmarks(i int) *[]*OperationBenchmark {
	return (*o.operationBenchmarkMatrix)[i]
}

func (o *OperationHandler) CloseChannels() {
	close(o.operationCalls)
	close(o.concurrentOperations)
}

func (o *OperationHandler) subOperationCall(opCall func() (*types.LogEntry, error), startTime time.Time) (*types.LogEntry, *OperationCallItem) {
	opBegin := time.Now()
	output, err := opCall()
	_ = output
	success := false
	if err == nil {
		success = true
	}
	return output, &OperationCallItem{
		Latency:           time.Since(opBegin).Microseconds(),
		Success:           success,
		RelativeTimestamp: time.Since(startTime).Microseconds(),
	}
}

func (o *OperationHandler) AppendCall(ctx context.Context, startTime time.Time, record []byte) {
	_, opItem := o.subOperationCall(
		func() (*types.LogEntry, error) {
			return Append(ctx, o.env, &AppendInput{Record: record})
		}, startTime)
	if !opItem.Success {
		(*(*o.operationBenchmarkMatrix)[o.snapshot])[0].AddFailure()
	} else {
		(*(*o.operationBenchmarkMatrix)[o.snapshot])[0].AddSuccess(opItem)
	}
	o.operationCalls <- struct{}{}
}

func (o *OperationHandler) AppendAndReadCall(ctx context.Context, startTime time.Time, record []byte, readTimes int, useTag bool) {
	tags := make([]uint64, 0)
	tag := constants.TagEmpty
	if useTag {
		tag = o.env.GenerateUniqueID()
		tags = append(tags, tag)
	}

	// append
	logEntry, opItem := o.subOperationCall(
		func() (*types.LogEntry, error) {
			return Append(ctx, o.env, &AppendInput{Record: record, Tags: tags})
		}, startTime)
	if !opItem.Success {
		(*(*o.operationBenchmarkMatrix)[o.snapshot])[0].AddFailure()
		// skip reading calls
		for i := 1; i <= readTimes; i++ {
			(*(*o.operationBenchmarkMatrix)[o.snapshot])[i].AddFailure()
		}
		o.operationCalls <- struct{}{}
		return
	}
	(*(*o.operationBenchmarkMatrix)[o.snapshot])[0].AddSuccess(opItem)

	//reads
	for i := 1; i <= readTimes; i++ {
		logEntry, opItem = o.subOperationCall(
			func() (*types.LogEntry, error) {
				return ReadNext(ctx, o.env, tag, logEntry.SeqNum)
			}, startTime)
		if !opItem.Success {
			// skip remaining reading calls
			for j := i; j <= readTimes; j++ {
				(*(*o.operationBenchmarkMatrix)[o.snapshot])[j].AddFailure()
			}
			o.operationCalls <- struct{}{}
			return
		}
		opItem.EngineCacheHit = utils.IsUint64InSlice(constants.TagEngineCacheHit, logEntry.Tags)
		(*(*o.operationBenchmarkMatrix)[o.snapshot])[i].AddSuccess(opItem)
	}
	o.operationCalls <- struct{}{}
}

func (o *OperationHandler) OperationFinished() {
	for {
		_, more := <-o.operationCalls //end of op
		if !more {
			break
		}
		o.wg.Done()
		o.concurrentOperations <- struct{}{}
	}
}
