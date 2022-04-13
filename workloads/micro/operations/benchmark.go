package operations

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
	Latency              string `json:"latency"`
	Throughput           string `json:"throughput"`
	RecordSize           int    `json:"record_size"`
	Benchmark            string `json:"benchmark"`
	SnapshotInterval     int    `json:"snapshot_interval"`
	EngineNodes          int    `json:"engine_nodes"`
	StorageNodes         int    `json:"storage_nodes"`
	SequencerNodes       int    `json:"sequencer_nodes"`
	IndexNodes           int    `json:"index_nodes"`
	ConcurrentClients    int    `json:"concurrency_client"`
	ConcurrentEngines    int    `json:"concurrency_engines"`
	ConcurrentWorkers    int    `json:"concurrency_workers"`
	ConcurrentOperations int    `json:"concurrency_operations"`
	UseTags              bool   `json:"use_tags"`
}

type Benchmark struct {
	Id                  uuid.UUID             `json:"uuid"`
	Success             uint                  `json:"calls_success"`
	Calls               uint                  `json:"calls"`
	ConcurrentFunctions int                   `json:"concurrent_functions"`
	Operations          []*OperationBenchmark `json:"operations"`
	Message             string                `json:"message,omitempty"`
	TimeLog             TimeLog               `json:"time_log,omitempty"`
	Description         Description           `json:"description,omitempty"`
	Throughput          float64               `json:"throughput"`
}

type OperationBenchmark struct {
	Calls          uint             `json:"calls"`
	Success        uint             `json:"calls_success"`
	AverageLatency float64          `json:"latency_average"`
	BucketLatency  Bucket           `json:"bucket"`
	HeadLatency    PriorityQueueMin `json:"latency_head"`
	TailLatency    PriorityQueueMax `json:"latency_tail"`
	EngineCacheHit uint             `json:"engine_cache_hit"`
	Description    string           `json:"description"`
}

func (this *OperationBenchmark) AddSuccess(item *OperationCallItem) {
	this.Calls++
	this.Success++
	s := float64(this.Success)
	this.AverageLatency = ((s-1)/s)*this.AverageLatency + (1/s)*float64(item.Latency)
	this.BucketLatency.Insert(item.Latency)
	this.HeadLatency.Add(item)
	this.TailLatency.Add(item)
	if item.EngineCacheHit {
		this.EngineCacheHit++
	}
}

func (this *OperationBenchmark) AddFailure() {
	this.Calls++
}

func CreateInitialOperationResult(Description string, latencyBucketLower int64, latencyBucketUpper int64, latencyBucketGranularity int64, latencyHeadSize int, latencyTailSize int) *OperationBenchmark {
	return &OperationBenchmark{
		Calls:         0,
		Success:       0,
		Description:   Description,
		BucketLatency: *CreateBucket(latencyBucketLower, latencyBucketUpper, latencyBucketGranularity),
		HeadLatency: PriorityQueueMin{
			Items: []*OperationCallItem{},
			Limit: latencyHeadSize,
		},
		TailLatency: PriorityQueueMax{
			Items: []*OperationCallItem{},
			Limit: latencyTailSize,
		},
	}
}

func CreateEmptyOperationResult() *OperationBenchmark {
	return &OperationBenchmark{}
}

func (this *OperationBenchmark) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*OperationBenchmark)
	this.Calls += other.Calls
	if this.Description != other.Description {
		log.Print("[WARNING] Cannot merge different operations")
		return
	}
	if other.Success == 0 {
	} else if this.Success == 0 {
		this.Success = other.Success
		this.AverageLatency = other.AverageLatency
		this.BucketLatency = other.BucketLatency
		this.HeadLatency = other.HeadLatency
		this.EngineCacheHit = other.EngineCacheHit
	} else {
		this.AverageLatency =
			this.AverageLatency*(float64(this.Success)/(float64(this.Success)+float64(other.Success))) +
				other.AverageLatency*(float64(other.Success)/(float64(this.Success)+float64(other.Success)))
		this.Success += other.Success
		for i := range other.BucketLatency.Slots {
			this.BucketLatency.Slots[i] += other.BucketLatency.Slots[i]
		}
		this.HeadLatency.Merge(&other.HeadLatency)
		this.TailLatency.Merge(&other.TailLatency)
		this.EngineCacheHit += other.EngineCacheHit
	}

}

func (this *Benchmark) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*Benchmark)
	if this.Id == other.Id {
		log.Print("[WARNING] Cannot merge same responses")
		return
	}
	if len(this.Operations) != len(other.Operations) {
		log.Print("[WARNING] Cannot merge different operation sizes")
		return
	}
	for i := range this.Operations {
		this.Operations[i].Merge(other.Operations[i])
	}
	this.Calls += other.Calls
	this.Success += other.Success
	this.Throughput += other.Throughput
	this.ConcurrentFunctions += other.ConcurrentFunctions
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
