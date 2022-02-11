package handlers

import (
	"context"
	"encoding/json"

	"cs.utexas.edu/zjia/faas-micro/utils"
	"cs.utexas.edu/zjia/faas/types"
)

type ReadInput struct {
	Seqnum uint64 `json:"seqnum"`
}

type ReadOutput struct {
	Success bool   `json:"successRead"`
	Message string `json:"message,omitempty"`
}

type readHandler struct {
	kind string
	env  types.Environment
}

func NewReadHandler(env types.Environment) types.FuncHandler {
	return &readHandler{
		kind: "read",
		env:  env,
	}
}

func (h *readHandler) read(ctx context.Context, env types.Environment, input *ReadInput) (*ReadOutput, error) {
	uniqueId := env.GenerateUniqueID()
	tags := []uint64{uniqueId}
	seqNum, err := env.SharedLogAppend(ctx, tags, []byte(utils.KbString()))
	if err != nil {
		return &ReadOutput{
			Success: false,
		}, err
	}
	logEntry, err := env.SharedLogReadNext(ctx, uniqueId, seqNum)
	if err != nil {
		return &ReadOutput{
			Success: false,
		}, err
	}
	return &ReadOutput{
		Success: true,
		Message: string(logEntry.Data),
	}, nil
}

func (h *readHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	parsedInput := &ReadInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	output, err := h.read(ctx, h.env, parsedInput)
	if err != nil {
		return nil, err
	}
	return json.Marshal(output)
}
