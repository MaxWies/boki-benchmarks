package main

import (
	"fmt"

	"cs.utexas.edu/zjia/faas"
	"cs.utexas.edu/zjia/faas-micro/handlers"
	"cs.utexas.edu/zjia/faas/types"
)

type funcHandlerFactory struct {
}

func (f *funcHandlerFactory) New(env types.Environment, funcName string) (types.FuncHandler, error) {
	switch funcName {
	case "AppendToLog":
		return handlers.NewAppendHandler(env), nil
	case "ReadFromLog":
		return handlers.NewReadHandler(env), nil
	case "AppendToAndReadFromLog":
		return handlers.NewAppendAndReadHandler(env), nil
	case "AppendToLogLoop":
		return handlers.NewAppendLoopHandler(env), nil
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
