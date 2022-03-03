package main

import (
	"fmt"

	"faas-micro/constants"
	"faas-micro/handlers"

	"cs.utexas.edu/zjia/faas"
	"cs.utexas.edu/zjia/faas/types"
)

type funcHandlerFactory struct {
}

func (f *funcHandlerFactory) New(env types.Environment, funcName string) (types.FuncHandler, error) {
	switch funcName {
	case constants.FunctionAppend:
		return handlers.NewAppendHandler(env), nil
	case constants.FunctionRead:
		return handlers.NewReadHandler(env), nil
	case constants.FunctionAppendAndRead:
		return handlers.NewAppendAndReadHandler(env), nil
	case constants.FunctionAppendLoop:
		return handlers.NewAppendLoopHandler(env, false), nil
	case constants.FunctionAppendLoopAsync:
		return handlers.NewAppendLoopHandler(env, true), nil
	case constants.FunctionMergeResults:
		return handlers.NewMergeHandler(), nil
	default:
		return nil, fmt.Errorf("Unknown function name: %s", funcName)
	}
}

func (f *funcHandlerFactory) GrpcNew(env types.Environment, service string) (types.GrpcFuncHandler, error) {
	return nil, fmt.Errorf("Not implemented")
}

func main() {
	faas.Serve(&funcHandlerFactory{})
}
