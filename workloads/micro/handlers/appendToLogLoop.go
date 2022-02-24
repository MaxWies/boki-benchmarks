package handlers

import (
	"context"
	"encoding/json"
	"time"

	"cs.utexas.edu/zjia/faas-micro/utils"
	"cs.utexas.edu/zjia/faas/types"
)

// Input from client
type AppendLoopInput struct {
	Record                   []byte `json:"record"`
	LoopDuration             int    `json:"loop_duration"`
	LatencyBucketLower       int64  `json:"latency_bucket_lower"`
	LatencyBucketUpper       int64  `json:"latency_bucket_upper"`
	LatencyBucketGranularity int64  `json:"latency_bucket_granularity"`
}

type AppendLoopOutput struct {
	Success bool   `json:"success"`
	Seqnum  uint64 `json:"seqnum"`
	Message string `json:"message,omitempty"`
}

type AppendLoopResponse struct {
	Success        uint         `json:"success"`
	Calls          uint         `json:"calls"`
	Throughput     float64      `json:"throughput"`
	AverageLatency float64      `json:"average_latency"`
	BucketLatency  utils.Bucket `json:"bucket"`
}

type appendLoopHandler struct {
	kind string
	env  types.Environment
}

func NewAppendLoopHandler(env types.Environment) types.FuncHandler {
	return &appendHandler{
		kind: "append",
		env:  env,
	}
}

func (h *appendLoopHandler) append(ctx context.Context, env types.Environment, input *AppendLoopInput) (*AppendLoopOutput, error) {
	uniqueId := env.GenerateUniqueID()
	tags := []uint64{uniqueId}
	seqNum, err := env.SharedLogAppend(ctx, tags, input.Record)
	if err != nil {
		return &AppendLoopOutput{
			Success: false,
			Seqnum:  0,
		}, err
	}
	return &AppendLoopOutput{
		Success: true,
		Seqnum:  seqNum,
	}, nil
}

func (h *appendLoopHandler) Call(ctx context.Context, input []byte) ([]byte, error) {

	parsedInput := &AppendLoopInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}

	startTime := time.Now()
	success := float64(0)
	calls := uint(0)
	avg_latency := float64(0)
	bucketLatency := utils.CreateBucket(parsedInput.LatencyBucketLower, parsedInput.LatencyBucketUpper, parsedInput.LatencyBucketGranularity)
	for {
		if time.Since(startTime) > time.Duration(parsedInput.LoopDuration)*time.Second {
			break
		}

		// call append
		appendBegin := time.Now()
		output, err := h.append(ctx, h.env, parsedInput)
		appendDuration := time.Since(appendBegin).Microseconds()

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
	return json.Marshal(response)
}
