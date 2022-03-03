package response

import (
	"encoding/json"
	"faas-micro/merge"
	"faas-micro/utils"
	"io/ioutil"
	"log"
	"path"

	"github.com/google/uuid"
)

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

func (this *TimeLog) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*TimeLog)
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

type Description struct {
	Latency    string `json:"latency"`
	Throughput string `json:"throughput"`
	RecordSize string `json:"record_size"`
	Benchmark  string `json:"benchmark"`
	Engines    int    `json:"engines"`
}

type Benchmark struct {
	Id                  uuid.UUID              `json:"uuid"`
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

func (this *Benchmark) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*Benchmark)
	if this.Id == other.Id {
		log.Print("[WARNING] Cannot merge same responses")
		return
	}
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

func (this *Benchmark) WriteToFile(directory string, fileName string) error {
	marshalled, err := json.Marshal(this)
	if err != nil {
		log.Printf("[ERROR] Could not marshall object")
		return err
	}
	filePath := path.Join(directory, fileName)
	log.Printf("[INFO] Write benchmark as %s", filePath)
	err = ioutil.WriteFile(filePath, marshalled, 0644)
	if err != nil {
		log.Printf("[ERROR] Failed to write to file %s", filePath)
	}
	return err
}
