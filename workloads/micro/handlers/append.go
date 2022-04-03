package handlers

import (
	"context"
	"encoding/json"
	"log"

	"faas-micro/constants"
	"faas-micro/utils"

	"cs.utexas.edu/zjia/faas/types"
)

type AppendInput struct {
	UseTags bool `json:"use_tags"`
}

type AppendOutput struct {
	Success bool   `json:"success"`
	Seqnum  uint64 `json:"seqnum"`
	Message string `json:"message,omitempty"`
}

type appendHandler struct {
	kind string
	env  types.Environment
}

func NewAppendHandler(env types.Environment) types.FuncHandler {
	return &appendHandler{
		kind: "append",
		env:  env,
	}
}

func (h *appendHandler) append(ctx context.Context, env types.Environment, input *AppendInput) (*AppendOutput, error) {
	tags := make([]uint64, 0)
	tag := constants.TagEmpty
	if input.UseTags {
		tag = env.GenerateUniqueID()
		tags = append(tags, tag)
	}
	seqNum, err := env.SharedLogAppend(ctx, tags, []byte(utils.KbString()))
	if err != nil {
		log.Printf("[ERROR] %v", err)
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

func (h *appendHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	parsedInput := &AppendInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	output, err := h.append(ctx, h.env, parsedInput)
	if err != nil {
		return nil, err
	}
	return json.Marshal(output)
}
