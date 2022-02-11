package handlers

import (
	"context"
	"encoding/json"

	"cs.utexas.edu/zjia/faas-micro/utils"
	"cs.utexas.edu/zjia/faas/types"
)

const readTimes = 3

type AppendAndReadInput struct {
}

type AppendAndReadOutput struct {
	Success bool   `json:"success"`
	Seqnum  uint64 `json:"seqnum"`
	Message string `json:"message,omitempty"`
}

type appendAndReadHandler struct {
	kind string
	env  types.Environment
}

func NewAppendAndReadHandler(env types.Environment) types.FuncHandler {
	return &appendAndReadHandler{
		kind: "appendAndRead",
		env:  env,
	}
}

func (h *appendAndReadHandler) appendAndRead(ctx context.Context, env types.Environment, input *AppendAndReadInput) (*AppendAndReadOutput, error) {
	uniqueId := env.GenerateUniqueID()
	tags := []uint64{uniqueId}
	seqNum, err := env.SharedLogAppend(ctx, tags, []byte(utils.KbString()))
	if err != nil {
		return &AppendAndReadOutput{
			Success: false,
			Seqnum:  0,
		}, err
	}
	var logEntry types.LogEntry
	for i := 0; i < readTimes; i++ {
		result, err := env.SharedLogReadNext(ctx, uniqueId, seqNum)
		logEntry = *result
		if err != nil {
			return &AppendAndReadOutput{
				Success: false,
				Seqnum:  0,
			}, err
		}
	}
	return &AppendAndReadOutput{
		Success: true,
		Seqnum:  seqNum,
		Message: string(logEntry.Data),
	}, nil
}

func (h *appendAndReadHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	parsedInput := &AppendAndReadInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	output, err := h.appendAndRead(ctx, h.env, parsedInput)
	if err != nil {
		return nil, err
	}
	return json.Marshal(output)
}
