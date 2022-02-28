package handlers

import (
	"context"
	"encoding/json"
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
}

// Response sync
type AppendLoopResponse struct {
	Success        uint         `json:"success"`
	Calls          uint         `json:"calls"`
	Throughput     float64      `json:"throughput"`
	AverageLatency float64      `json:"average_latency"`
	BucketLatency  utils.Bucket `json:"bucket"`
	Message        string       `json:"message,omitempty"`
}

func (this AppendLoopResponse) Merge(object merge.Mergable) {
	other := object.(AppendLoopResponse)
	this.AverageLatency =
		this.AverageLatency*(float64(this.Success)/(float64(this.Success)+float64(other.Success))) +
			other.AverageLatency*(float64(other.Success)/(float64(this.Success)+float64(other.Success)))
	this.Calls += other.Calls
	this.Success += other.Success
	for i := range other.BucketLatency.Slots {
		this.BucketLatency.Slots[i] += other.BucketLatency.Slots[i]
	}
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
	startTime := time.Now()
	success := float64(0)
	calls := uint(0)
	avg_latency := float64(0)
	//log.Printf("[INFO] Create bucket")
	bucketLatency := utils.CreateBucket(parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity)
	//log.Printf("[INFO] Run loop")
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

		calls++
		if err == nil {
			success++
			avg_latency = ((success-1)/success)*avg_latency + (1/success)*float64(appendDuration)
			bucketLatency.Insert(appendDuration)
		}
		_ = output
	}
	throughput := float64(success) / float64(time.Since(startTime).Seconds())

	response := &AppendLoopResponse{
		Success:        uint(success),
		Calls:          calls,
		Throughput:     throughput,
		AverageLatency: float64(avg_latency),
		BucketLatency:  *bucketLatency,
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
