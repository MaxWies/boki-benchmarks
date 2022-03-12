package operations

// import (
// 	"context"
// 	"faas-micro/response"
// 	"faas-micro/utils"
// 	"time"

// 	"cs.utexas.edu/zjia/faas/types"
// )

// type operation interface {
// 	Call(ctx context.Context, logEntry *types.LogEntry) (*types.LogEntry, error)
// }

// type OperationSequence struct {
// }

// func buildSequenceScript() *OperationSequence {
// 	for op := range o.operationCalls {
// 		op.Call()
// 	}

// 	// operationCall Append
// 	// f := func() (*types.LogEntry, error) {
// 	// 	return Append(ctx, o.env, &AppendInput{Record: record})
// 	// }
// 	o.callOperation(func() (*types.LogEntry, error) {
// 		return Append(ctx, o.env, &AppendInput{Record: record})
// 	}, startTime, call)
// 	// operationCall Read
// 	o.callOperation(func() (*types.LogEntry, error) {
// 		return ReadNext(ctx, o.env, &AppendInput{Record: record})
// 	}, startTime, call)
// }

// type operationHandler struct {
// 	env               types.Environment
// 	duration          int
// 	operationCalls    chan *utils.OperationCallItem
// 	operations        []*response.Operation
// 	operationSequence *OperationSequence
// }

// func NewOperationHandler(env types.Environment, duration int, concurrency int) {

// }

// func (o *operationHandler) callOperation(opCall func() (*types.LogEntry, error), startTime time.Time, call int64) (*types.LogEntry, error) {
// 	appendBegin := time.Now()
// 	output, err := opCall() //operations.Append(ctx, o.env, &operations.AppendInput{Record: record})
// 	_ = output
// 	success := false
// 	if err == nil {
// 		success = true
// 	}
// 	o.operationCalls <- &utils.OperationCallItem{
// 		Latency:           time.Since(appendBegin).Microseconds(),
// 		Call:              call,
// 		Success:           success,
// 		RelativeTimestamp: time.Since(startTime).Microseconds(),
// 	}
// 	return output, err
// }

// func (o *operationHandler) RunOperationSequence(ctx context.Context, startTime time.Time, call int64, record []byte) {
// 	for op := range o.operationCalls {
// 		op.Call()
// 	}

// 	// operationCall Append
// 	// f := func() (*types.LogEntry, error) {
// 	// 	return Append(ctx, o.env, &AppendInput{Record: record})
// 	// }
// 	o.callOperation(func() (*types.LogEntry, error) {
// 		return Append(ctx, o.env, &AppendInput{Record: record})
// 	}, startTime, call)
// 	// operationCall Read
// 	o.callOperation(func() (*types.LogEntry, error) {
// 		return ReadNext(ctx, o.env, &AppendInput{Record: record})
// 	}, startTime, call)
// }
