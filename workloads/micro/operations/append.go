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

func Append(ctx context.Context, env types.Environment, input *AppendInput) (*AppendOutput, error) {
	//uniqueId := env.GenerateUniqueID()
	if input.Tags == nil {
		input.Tags = make([]uint64, 0)
	}
	seqNum, err := env.SharedLogAppend(ctx, input.Tags, input.Record)
	if err != nil {
		return &AppendOutput{
			Success: false,
			Seqnum:  0,
		}, err
	}
	return &AppendOutput{
		Success: true,
		Seqnum:  seqNum,
	}, nil
}
