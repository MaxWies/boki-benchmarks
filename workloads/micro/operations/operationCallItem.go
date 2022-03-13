package operations

type OperationCallItem struct {
	Latency           int64 `json:"latency"`
	Success           bool  `json:"success"`
	RelativeTimestamp int64 `json:"relative_timestamp"`
}
