package operations

import (
	"context"
	"errors"
	"faas-micro/constants"
	"log"

	"cs.utexas.edu/zjia/faas/types"
)

type ReadInput struct {
	Seqnum uint64 `json:"seqnum"`
}

type ReadOutput struct {
	Success bool   `json:"successRead"`
	Message string `json:"message,omitempty"`
}

func Read(ctx context.Context, env types.Environment, tag uint64, seqNum uint64, readDirection int) (*types.LogEntry, error) {
	if readDirection == constants.ReadNext {
		return env.SharedLogReadNext(ctx, tag, seqNum)
	} else if readDirection == constants.ReadPrev {
		return env.SharedLogReadPrev(ctx, tag, seqNum)
	} else {
		log.Printf("[FATAL] Invalid read direction %d", readDirection)
		return nil, errors.New("This direction is invalid")
	}
}
