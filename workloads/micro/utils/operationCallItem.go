package utils

type OperationCallItem struct {
	Latency           int64 `json:"latency"`
	Call              int64 `json:"call"`
	RelativeTimestamp int64 `json:"relative_timestamp"`
}
