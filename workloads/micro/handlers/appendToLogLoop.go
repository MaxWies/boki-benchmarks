package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"path"
	"time"

	"faas-micro/constants"
	"faas-micro/merge"
	"faas-micro/operations"

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
}

type TimeLog struct {
	LoopDuration int   `json:"loop_duration"`  // original duration
	StartTime    int64 `json:"time_start"`     // start time of concurrent running
	EndTime      int64 `json:"time_end"`       // end time of concurrent running
	MinStartTime int64 `json:"time_start_min"` // the smallest start time seen
	MaxStartTime int64 `json:"time_start_max"` // the latest start time seen
	MinEndTime   int64 `json:"time_end_min"`   // the smallest end time seen
	MaxEndTime   int64 `json:"time_end_max"`   // the latest end time seen
	Valid        bool  `json:"valid"`          // if time log appears valid or not
}

type Description struct {
	Latency    string `json:"latency"`
	Throughput string `json:"throughput"`
	RecordSize string `json:"record_size"`
	Benchmark  string `json:"benchmark"`
}

func (this *TimeLog) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*TimeLog)
	// if this.LoopDuration != other.LoopDuration {
	// 	return error
	// }
	this.StartTime = utils.Max(this.StartTime, other.StartTime)
	this.EndTime = utils.Min(this.EndTime, other.EndTime)
	this.MinStartTime = utils.Min(this.MinStartTime, other.MinStartTime)
	this.MaxStartTime = utils.Max(this.MaxStartTime, other.MaxStartTime)
	this.MinEndTime = utils.Min(this.MinEndTime, other.MinEndTime)
	this.MaxEndTime = utils.Max(this.MaxEndTime, other.MaxEndTime)
	this.Valid = this.Valid && other.Valid
	if this.StartTime >= this.EndTime || this.LoopDuration != other.LoopDuration {
		this.Valid = false
	}
}

// Response sync
type AppendLoopResponse struct {
	Success             uint                   `json:"calls_success"`
	Calls               uint                   `json:"calls"`
	Throughput          float64                `json:"throughput"`
	AverageLatency      float64                `json:"latency_average"`
	BucketLatency       utils.Bucket           `json:"bucket"`
	HeadLatency         utils.PriorityQueueMin `json:"latency_head"`
	TailLatency         utils.PriorityQueueMax `json:"latency_tail"`
	Message             string                 `json:"message,omitempty"`
	TimeLog             TimeLog                `json:"time_log,omitempty"`
	Description         Description            `json:"description,omitempty"`
	ConcurrentFunctions int                    `json:"concurrent_functions"`
}

func (this *AppendLoopResponse) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*AppendLoopResponse)
	this.AverageLatency =
		this.AverageLatency*(float64(this.Success)/(float64(this.Success)+float64(other.Success))) +
			other.AverageLatency*(float64(other.Success)/(float64(this.Success)+float64(other.Success)))
	this.Throughput += other.Throughput
	this.Calls += other.Calls
	this.Success += other.Success
	this.ConcurrentFunctions += other.ConcurrentFunctions
	for i := range other.BucketLatency.Slots {
		this.BucketLatency.Slots[i] += other.BucketLatency.Slots[i]
	}
	this.HeadLatency.Merge(&other.HeadLatency)
	this.TailLatency.Merge(&other.TailLatency)
	this.TimeLog.Merge(&other.TimeLog)
}

// Response async
type AppendLoopAsyncResponse struct {
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

	response := &AppendLoopResponse{
		Success:             uint(success),
		Calls:               calls,
		Throughput:          throughput,
		AverageLatency:      float64(avg_latency),
		BucketLatency:       *bucketLatency,
		HeadLatency:         headLatency,
		TailLatency:         tailLatency,
		ConcurrentFunctions: 1,
		TimeLog: TimeLog{
			LoopDuration: parsedInput.LoopDuration,
			StartTime:    startTime.UnixNano(),
			EndTime:      endTime.UnixNano(),
			MinStartTime: startTime.UnixNano(),
			MaxStartTime: startTime.UnixNano(),
			MinEndTime:   endTime.UnixNano(),
			MaxEndTime:   endTime.UnixNano(),
			Valid:        true,
		},
		Description: Description{
			Benchmark:  "Append to Log",
			Throughput: "[Op/s] Operations per second",
			Latency:    "[microsec] Operation latency",
			RecordSize: fmt.Sprintf("[byte] %d", len((parsedInput.Record))),
		},
	}

	log.Printf("[INFO] Loop finished. %d calls successful from %d total calls", int(success), calls)

	marshalledResponse, err := json.Marshal(response)

	if h.isAsync {
		uuid := uuid.New().String()
		filePath := path.Join(constants.BASE_PATH_ENGINE_BOKI_BENCHMARK, constants.AppendLoopAsync, uuid)
		err = ioutil.WriteFile(filePath, marshalledResponse, 0644)
		if err != nil {
			return nil, err
		}
		return json.Marshal(&AppendLoopAsyncResponse{})
	} else {
		return marshalledResponse, err
	}
}
