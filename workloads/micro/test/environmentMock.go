package test

import (
	"context"
	"log"
	"math/rand"
	"time"

	"cs.utexas.edu/zjia/faas/types"
)

type EnvironmentMock struct {
}

func (m *EnvironmentMock) InvokeFunc(ctx context.Context, funcName string, input []byte) ([]byte, error) {
	return make([]byte, 0), nil
}

func (m *EnvironmentMock) InvokeFuncAsync(ctx context.Context, funcName string, input []byte) error {
	return nil
}

func (m *EnvironmentMock) GrpcCall(ctx context.Context, service string, method string, request []byte) ( /* reply */ []byte, error) {
	return make([]byte, 0), nil
}

func (m *EnvironmentMock) GenerateUniqueID() uint64 {
	return 42
}

func (m *EnvironmentMock) SharedLogAppend(ctx context.Context, tags []uint64, data []byte) (uint64, error) {
	r := rand.Float64()
	s := int64(2000 * r)
	log.Printf("[INFO] Append: Artificial wait of %d microseconds\n", s)
	time.Sleep(time.Duration(s) * time.Microsecond)
	return 42, nil
}

func (m *EnvironmentMock) SharedLogReadNext(ctx context.Context, tag uint64, seqNum uint64) (*types.LogEntry, error) {
	r := rand.Float64()
	s := int64(1000 * r)
	log.Printf("[INFO] Append: Artificial wait of %d microseconds\n", s)
	time.Sleep(time.Duration(s) * time.Microsecond)
	return &types.LogEntry{}, nil
}

func (m *EnvironmentMock) SharedLogReadNextBlock(ctx context.Context, tag uint64, seqNum uint64) (*types.LogEntry, error) {
	return &types.LogEntry{}, nil
}

func (m *EnvironmentMock) SharedLogReadPrev(ctx context.Context, tag uint64, seqNum uint64) (*types.LogEntry, error) {
	return &types.LogEntry{}, nil
}

func (m *EnvironmentMock) SharedLogCheckTail(ctx context.Context, tag uint64) (*types.LogEntry, error) {
	return &types.LogEntry{}, nil
}

func (m *EnvironmentMock) SharedLogSetAuxData(ctx context.Context, seqNum uint64, auxData []byte) error {
	return nil
}
