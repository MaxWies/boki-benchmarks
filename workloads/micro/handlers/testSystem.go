package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"

	"faas-micro/constants"
	"faas-micro/operations"
	"faas-micro/utils"

	"cs.utexas.edu/zjia/faas/types"
)

type TestSystemInput struct {
	Record    []byte `json:"record"`
	ReadTimes int    `json:"read_times"`
	Tag       uint64 `json:"tag"`
}

type TestSystemOutput struct {
	Success bool   `json:"success"`
	Seqnum  uint64 `json:"seqnum"`
	Message string `json:"message,omitempty"`
}

type testSystemHandler struct {
	kind string
	env  types.Environment
}

func NewTestSystemHandler(env types.Environment) types.FuncHandler {
	return &testSystemHandler{
		kind: "testSytem",
		env:  env,
	}
}

func TestReadResultExist(log_entry *types.LogEntry) bool {
	if log_entry == nil {
		return false
	}
	if log_entry.Data == nil {
		return false
	}
	return true
}

func TestReadResultCorrect(input *TestSystemInput, log_entry *types.LogEntry) bool {
	if len(input.Record) != len(log_entry.Data) {
		return false
	}
	for i := range input.Record {
		if input.Record[i] != log_entry.Data[i] {
			return false
		}
	}
	return true
}

func (h *testSystemHandler) testSystem(ctx context.Context, env types.Environment, input *TestSystemInput) (*TestSystemOutput, error) {
	// PREPARE
	tags := make([]uint64, 0)
	if input.Tag != constants.TagEmpty {
		tags = append(tags, input.Tag)
	}
	// APPEND
	appendResult, err := operations.Append(ctx, env, &operations.AppendInput{Record: input.Record, Tags: tags})
	if err != nil {
		return &TestSystemOutput{
			Success: false,
			Seqnum:  0,
		}, err
	}
	// READ
	for i := 0; i < input.ReadTimes; i++ {
		var readResult *types.LogEntry
		var err error
		if input.Tag == constants.TagEmpty {
			// read own seqnum directly
			readResult, err = operations.Read(ctx, env, input.Tag, appendResult.SeqNum, rand.Intn(2))
		} else {
			readType := rand.Intn(100)
			if readType < 30 {
				// read seqnum for tag from 0 upwards
				readResult, err = operations.Read(ctx, env, input.Tag, 0, constants.ReadNext)
			} else if readType < 70 {
				// read seqnum for tag directly
				readResult, err = operations.Read(ctx, env, input.Tag, appendResult.SeqNum, rand.Intn(2))
			} else {
				// read seqnum for tag from tail downwards
				readResult, err = operations.Read(ctx, env, input.Tag, constants.MaxSeqnum, constants.ReadPrev)
			}
		}
		if err != nil {
			return &TestSystemOutput{
				Success: false,
				Seqnum:  0,
			}, err
		}
		if !TestReadResultExist(readResult) {
			log.Printf("[ERROR] Read result is nil or its data is nil. append_seqnum=%s, tag=%d", utils.HexStr0x(appendResult.SeqNum), input.Tag)
			return &TestSystemOutput{
				Success: false,
				Seqnum:  appendResult.SeqNum,
				Message: fmt.Sprintf("Read result is nil or its data is nil. append_seqnum=%s, tag=%d", utils.HexStr0x(appendResult.SeqNum), input.Tag),
			}, nil
		}
		if !TestReadResultCorrect(input, readResult) {
			log.Printf("[ERROR] Read record not identical to the one appended before. append_seqnum=%s, read_seqnum=%s, tag=%d",
				utils.HexStr0x(appendResult.SeqNum), utils.HexStr0x(readResult.SeqNum), input.Tag)
			return &TestSystemOutput{
				Success: false,
				Seqnum:  appendResult.SeqNum,
				Message: fmt.Sprintf("Read record not identical to the one appended before. append_seqnum=%s, read_seqnum=%s, tag=%d",
					utils.HexStr0x(appendResult.SeqNum), utils.HexStr0x(readResult.SeqNum), input.Tag),
			}, nil
		}
		if appendResult.SeqNum != readResult.SeqNum {
			log.Printf("[ERROR] Seqnum of record not identical to the one of the record appended before. append_seqnum=%s, read_seqnum=%s, tag=%d",
				utils.HexStr0x(appendResult.SeqNum), utils.HexStr0x(readResult.SeqNum), input.Tag)
			return &TestSystemOutput{
				Success: false,
				Seqnum:  appendResult.SeqNum,
				Message: fmt.Sprintf("[ERROR] Seqnum of record not identical to the one of the record appended before. append_seqnum=%s, read_seqnum=%s, tag=%d",
					utils.HexStr0x(appendResult.SeqNum), utils.HexStr0x(readResult.SeqNum), input.Tag),
			}, nil
		}
	}
	// READ UNKNOWN TAG
	var readResult *types.LogEntry
	if rand.Intn(100) < 10 {
		readType := rand.Intn(100)
		if readType < 30 {
			readResult, err = operations.Read(ctx, env, constants.TagUnknown, 0, constants.ReadNext)
		} else if readType < 70 {
			readResult, err = operations.Read(ctx, env, constants.TagUnknown, appendResult.SeqNum, rand.Intn(2))
		} else {
			readResult, err = operations.Read(ctx, env, constants.TagUnknown, constants.MaxSeqnum, constants.ReadPrev)
		}
		if TestReadResultExist(readResult) {
			log.Printf("[ERROR] Read result is not nil for unknown tag. read_seqnum=%s, tag=%d", utils.HexStr0x(readResult.SeqNum), constants.TagUnknown)
			return &TestSystemOutput{
				Success: false,
				Seqnum:  readResult.SeqNum,
				Message: fmt.Sprintf("Read result is not nil for unknown tag. read_seqnum=%s, tag=%d", utils.HexStr0x(readResult.SeqNum), constants.TagUnknown),
			}, nil
		}
		if err != nil {
			return &TestSystemOutput{
				Success: false,
				Seqnum:  0,
			}, err
		}
	}

	return &TestSystemOutput{
		Success: true,
		Seqnum:  appendResult.SeqNum,
		Message: string(appendResult.Data),
	}, nil
}

func (h *testSystemHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	parsedInput := &TestSystemInput{}
	err := json.Unmarshal(input, parsedInput)
	if err != nil {
		return nil, err
	}
	output, err := h.testSystem(ctx, h.env, parsedInput)
	if err != nil {
		return nil, err
	}
	return json.Marshal(output)
}
