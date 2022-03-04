package operations

import (
	"context"

	"cs.utexas.edu/zjia/faas/types"
)

type ReadInput struct {
	Seqnum uint64 `json:"seqnum"`
}

type ReadOutput struct {
	Success bool   `json:"successRead"`
	Message string `json:"message,omitempty"`
}

func ReadNext(ctx context.Context, env types.Environment, tag uint64, seqNum uint64) (*types.LogEntry, error) {
	// logEntry, err := env.SharedLogReadNext(ctx, tag, seqNum)
	// if err != nil {
	// 	return &ReadOutput{
	// 		Success: false,
	// 	}, err
	// }
	// return &ReadOutput{
	// 	Success: true,
	// 	Message: string(logEntry.Data),
	// }, nil
	return env.SharedLogReadNext(ctx, tag, seqNum)
}
