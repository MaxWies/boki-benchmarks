package operations

import (
	"context"
	"faas-micro/constants"
	"faas-micro/utils"
	"fmt"
	"log"
	"math/rand"
	"strconv"
	"strings"
	"sync"
	"time"

	"cs.utexas.edu/zjia/faas/types"
)

type OperationInput struct {
	Record                       []byte `json:"record"`
	AppendTimes                  int    `json:"append_times"`
	ReadTimes                    int    `json:"read_times"`
	ReadDirection                int    `json:"read_direction"`
	UseTags                      bool   `json:"use_tags"`
	LoopDuration                 int    `json:"loop_duration"`
	SnapshotInterval             int    `json:"snapshot_interval"`
	LatencyBucketLower           int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper           int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity     int64  `json:"latency_bucket_granularity"`
	LatencyHeadSize              int    `json:"latency_head_size"`
	LatencyTailSize              int    `json:"latency_tail_size"`
	StatisticsAtContainer        bool   `json:"statistics_at_container"`
	BenchmarkType                string `json:"benchmark_type"`
	ConcurrentOperations         int    `json:"concurrent_operations"`
	SuffixSeqnumsCapacity        int    `json:"suffix_seqnums_capacity"`
	PopularSeqnumsCapacity       int    `json:"popular_seqnums_capacity"`
	OwnTagsCapacity              int    `json:"own_tags_capacity"`
	SharedTagsCapacity           int    `json:"shared_tags_capacity"`
	OperationSemanticsPercentage string `json:"operation_semantics_percentages"`
	SeqnumReadPercentages        string `json:"seqnum_read_percentages"`
	TagAppendPercentages         string `json:"tag_append_percentages"`
	TagReadPercentages           string `json:"tag_read_percentages"`
}

func (o *OperationInput) LogParameters() {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Benchmark type: %s\n", o.BenchmarkType))
	sb.WriteString(fmt.Sprintf("Record size: %d\n", len(o.Record)))
	sb.WriteString(fmt.Sprintf("Duration: %d\n", o.LoopDuration))
	sb.WriteString(fmt.Sprintf("Concurrent operations: %d\n", o.ConcurrentOperations))
	sb.WriteString(fmt.Sprintf("Record size: %d\n", len(o.Record)))
}

func createSharedTags(capacity int) utils.TagPool {
	if capacity < 1 {
		log.Printf("[INFO] No capacity for 'shared' tags given")
	}
	sharedTags := make([]uint64, capacity, capacity)
	for i := 0; i < capacity; i++ {
		sharedTags[i] = constants.TagShared + uint64(i)
	}
	return utils.CreateTagPool(sharedTags)
}

func createOwnTags(capacity int, env types.Environment) utils.TagPool {
	if capacity < 1 {
		log.Printf("[INFO] No capacity for 'own' tags given")
	}
	ownTags := make([]uint64, capacity, capacity)
	for i := 0; i < capacity; i++ {
		ownTags[i] = env.GenerateUniqueID()
	}
	return utils.CreateTagPool(ownTags)
}

func parsePercentages(s string) []int {
	parts := strings.Split(s, ",")
	results := make([]int, len(parts))
	for i, part := range parts {
		if parsed, err := strconv.Atoi(part); err != nil {
			log.Printf("[ERROR] Failed to parse %d-th part", i)
			return nil
		} else {
			results[i] = parsed
		}
	}
	for i := 1; i < len(results); i++ {
		results[i] += results[i-1]
	}
	if results[len(results)-1] != 100 {
		log.Print("[ERROR] Sum of all parts is not 100")
		return nil
	}
	return results
}

type StatisticsHandler struct {
	activated                bool
	operationBenchmarkMatrix *[]*[]*OperationBenchmark
	snapshot                 int
}

type OperationHandler struct {
	env                           types.Environment
	operationCalls                chan struct{}
	concurrentOperations          chan struct{}
	wg                            *sync.WaitGroup
	suffixSeqnums                 utils.LogSuffix
	popularSeqnums                utils.SeqnumPool
	suffixTags                    utils.LogSuffix
	ownTags                       utils.TagPool
	sharedTags                    utils.TagPool
	operationSemanticsPercentages []int
	seqnumReadPercentages         []int
	tagAppendPercentages          []int
	tagReadPercentages            []int
	statisticsHandler             *StatisticsHandler
}

func newOperationHandler(env types.Environment, input *OperationInput, operationBenchmarkMatrix *[]*[]*OperationBenchmark) *OperationHandler {
	op := &OperationHandler{
		env:                           env,
		operationCalls:                make(chan struct{}),
		concurrentOperations:          make(chan struct{}, input.ConcurrentOperations),
		wg:                            &sync.WaitGroup{},
		suffixSeqnums:                 utils.CreateLogSuffix(input.SuffixSeqnumsCapacity),
		popularSeqnums:                utils.CreateEmptySeqnumPool(input.PopularSeqnumsCapacity),
		ownTags:                       createOwnTags(input.OwnTagsCapacity, env),
		sharedTags:                    createSharedTags(input.SharedTagsCapacity),
		operationSemanticsPercentages: parsePercentages(input.OperationSemanticsPercentage),
		seqnumReadPercentages:         parsePercentages(input.SeqnumReadPercentages),
		tagAppendPercentages:          parsePercentages(input.TagAppendPercentages),
		tagReadPercentages:            parsePercentages(input.TagReadPercentages),
		statisticsHandler: &StatisticsHandler{
			activated:                input.StatisticsAtContainer,
			operationBenchmarkMatrix: operationBenchmarkMatrix,
			snapshot:                 0,
		},
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
	o.statisticsHandler.snapshot += 1
	*o.statisticsHandler.operationBenchmarkMatrix = append(*o.statisticsHandler.operationBenchmarkMatrix, operationBenchmarks)
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
	return (*o.statisticsHandler.operationBenchmarkMatrix)[i]
}

func (o *OperationHandler) CloseChannels() {
	close(o.operationCalls)
	close(o.concurrentOperations)
}

func (o *OperationHandler) subOperationCall(opCall func() (*types.LogEntry, error), startTime time.Time) (*types.LogEntry, *OperationCallItem) {
	opBegin := time.Now()
	output, err := opCall()
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

func (s *StatisticsHandler) StoreResult(opItem *OperationCallItem, recordIndex int) {
	if !s.activated {
		return
	}
	if opItem == nil || !opItem.Success {
		(*(*s.operationBenchmarkMatrix)[s.snapshot])[recordIndex].AddFailure()
	} else {
		(*(*s.operationBenchmarkMatrix)[s.snapshot])[recordIndex].AddSuccess(opItem)
	}
}

func (o *OperationHandler) AppendCall(ctx context.Context, startTime time.Time, record []byte) {
	_, opItem := o.subOperationCall(
		func() (*types.LogEntry, error) {
			return Append(ctx, o.env, &AppendInput{Record: record})
		}, startTime)
	o.statisticsHandler.StoreResult(opItem, 0)
	o.operationCalls <- struct{}{}
}

func (o *OperationHandler) AppendAndReadCall(ctx context.Context, startTime time.Time, record []byte, readTimes int, readDirection int, useTag bool) {
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
		o.statisticsHandler.StoreResult(nil, 0)
		// skip reading calls
		for i := 1; i <= readTimes; i++ {
			o.statisticsHandler.StoreResult(nil, i)
		}
		o.operationCalls <- struct{}{}
		log.Print("[WARNING] Append to log failed")
		return
	}
	o.statisticsHandler.StoreResult(opItem, 0)

	//reads
	for i := 1; i <= readTimes; i++ {
		logEntry, opItem = o.subOperationCall(
			func() (*types.LogEntry, error) {
				return Read(ctx, o.env, tag, logEntry.SeqNum, readDirection)
			}, startTime)
		if !opItem.Success {
			// skip remaining reading calls
			for j := i; j <= readTimes; j++ {
				o.statisticsHandler.StoreResult(nil, j)
			}
			o.operationCalls <- struct{}{}
			log.Printf("[WARNING] Read from log seqnum %d failed", logEntry.SeqNum)
		}
		opItem.EngineCacheHit = utils.IsUint64InSlice(constants.TagEngineCacheHit, logEntry.Tags)
		o.statisticsHandler.StoreResult(opItem, i)
	}
	o.operationCalls <- struct{}{}
}

func (o *OperationHandler) appendRecord(ctx context.Context, startTime time.Time, record []byte, tag uint64, appendTime int) (bool, uint64) {
	tags := make([]uint64, 0)
	if tag != constants.TagEmpty {
		tags = append(tags, tag)
	}
	logEntry, opItem := o.subOperationCall(
		func() (*types.LogEntry, error) {
			return Append(ctx, o.env, &AppendInput{Record: record, Tags: tags})
		}, startTime)
	if opItem.Success && logEntry.SeqNum == constants.InvalidSeqNum {
		// no success for invalid seqnum
		opItem.Success = false
	}
	o.statisticsHandler.StoreResult(opItem, appendTime)
	if !opItem.Success {
		logEntry.SeqNum = uint64(0)
	}
	return opItem.Success, logEntry.SeqNum
}

func (o *OperationHandler) readRecord(ctx context.Context, startTime time.Time, seqnum uint64, tag uint64, readDirection int, readTime int) {
	_, opItem := o.subOperationCall(
		func() (*types.LogEntry, error) {
			return Read(ctx, o.env, tag, seqnum, readDirection)
		}, startTime)
	o.statisticsHandler.StoreResult(opItem, readTime)
	if !opItem.Success {
		return
	}
}

func (o *OperationHandler) RandomAppendAndReadCall(ctx context.Context, startTime time.Time, record []byte, appendTimes int, readTimes int) {
	remaining_appends := appendTimes
	remaining_reads := readTimes
	opCounter := -1
	var seqnum uint64
	var tag uint64
	var tag_seqnum uint64
	var success bool
	for 0 < remaining_appends+remaining_reads {
		semanticType := rand.Intn(100)
		if semanticType < o.operationSemanticsPercentages[0] {
			// ops without tags
			if 0 < remaining_appends {
				opCounter++
				success, seqnum = o.appendRecord(ctx, startTime, record, constants.TagEmpty, opCounter)
				if success {
					o.suffixSeqnums.Append(constants.TagEmpty, seqnum)
					o.popularSeqnums.Append(seqnum) // will be filled until full
				} else {
					break
				}
			}
			if 0 < remaining_reads {
				opCounter++
				readOp := rand.Intn(100)
				if readOp < o.seqnumReadPercentages[0] {
					// read own seqnum
					o.readRecord(ctx, startTime, seqnum, constants.TagEmpty, rand.Intn(2), opCounter)
				} else if readOp < o.seqnumReadPercentages[1] {
					// read popular seqnum
					o.readRecord(ctx, startTime, o.popularSeqnums.PickRandomSeqnum(), constants.TagEmpty, rand.Intn(2), opCounter)
				} else if readOp < o.seqnumReadPercentages[2] {
					// read suffix seqnum
					o.readRecord(ctx, startTime, o.suffixSeqnums.PickRandomSeqnum(), constants.TagEmpty, rand.Intn(2), opCounter)
				} else if readOp < o.seqnumReadPercentages[3] {
					// read from 0
					o.readRecord(ctx, startTime, 0, constants.TagEmpty, constants.ReadNext, opCounter)
				} else {
					// read from tail
					o.readRecord(ctx, startTime, constants.MaxSeqnum, constants.TagEmpty, constants.ReadPrev, opCounter)
				}
			}
		} else {
			// ops with tags
			tag_seqnum_min := uint64(0)
			tag_seqnum_max := uint64(0)
			if 0 < remaining_appends {
				opCounter++
				appendOp := rand.Intn(100)
				if appendOp < o.tagAppendPercentages[0] {
					tag = o.env.GenerateUniqueID()
					success, tag_seqnum = o.appendRecord(ctx, startTime, record, tag, opCounter)
					if success {
						tag_seqnum_min = 0 //reset
						tag_seqnum_max = 0 //reset
					} else {
						break
					}
				} else if appendOp < o.tagAppendPercentages[1] {
					// append to own tag
					tag = o.ownTags.PickRandomTag()
					success, tag_seqnum = o.appendRecord(ctx, startTime, record, tag, opCounter)
					if success {
						tag_seqnum_min, tag_seqnum_max = o.ownTags.Update(tag, seqnum)
					} else {
						break
					}
				} else {
					// append to shared tag
					tag = o.sharedTags.PickRandomTag()
					success, tag_seqnum = o.appendRecord(ctx, startTime, record, tag, opCounter)
					if success {
						tag_seqnum_min, tag_seqnum_max = o.sharedTags.Update(tag, seqnum)
					} else {
						break
					}
				}
			}
			if 0 < remaining_reads {
				opCounter++
				readOp := rand.Intn(100)
				if readOp < o.tagReadPercentages[0] && tag_seqnum_min != tag_seqnum_max {
					// read gap
					o.readRecord(ctx, startTime, tag_seqnum_min+1, tag, constants.ReadNext, opCounter)
				} else if readOp < o.tagReadPercentages[1] {
					// read tag directly
					o.readRecord(ctx, startTime, tag_seqnum, tag, rand.Intn(2), opCounter)
				} else if readOp < o.tagReadPercentages[2] {
					// read tag from left (next)
					o.readRecord(ctx, startTime, tag_seqnum-5, tag, constants.ReadNext, opCounter)
				} else if readOp < o.tagReadPercentages[3] {
					// read tag from right (prev)
					o.readRecord(ctx, startTime, tag_seqnum+5, tag, constants.ReadPrev, opCounter)
				} else if readOp < o.tagReadPercentages[4] {
					// read tag from 0
					o.readRecord(ctx, startTime, 0, tag, constants.ReadNext, opCounter)
				} else {
					// read tag from tail
					o.readRecord(ctx, startTime, constants.MaxSeqnum, tag, constants.ReadPrev, opCounter)
				}
			}
		}
		if 0 < remaining_appends {
			remaining_appends--
		}
		if 0 < readTimes {
			remaining_reads--
		}
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
