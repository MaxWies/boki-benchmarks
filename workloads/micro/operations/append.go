package operations

import (
	"context"

	"cs.utexas.edu/zjia/faas/types"
)

type AppendInput struct {
	Record []byte
	Tags   []uint64
}

type AppendOutput struct {
	Success bool   `json:"success"`
	Seqnum  uint64 `json:"seqnum"`
	Message string `json:"message,omitempty"`
}

func Append(ctx context.Context, env types.Environment, input *AppendInput) (*types.LogEntry, error) {
	if input.Tags == nil {
		input.Tags = make([]uint64, 0)
	}
	seqNum, err := env.SharedLogAppend(ctx, input.Tags, input.Record)
	return &types.LogEntry{
			SeqNum: seqNum,
		},
		err
}
