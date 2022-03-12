package main

import (
	"fmt"
	"strings"

	"faas-micro/constants"
	"faas-micro/handlers"

	"cs.utexas.edu/zjia/faas"
	"cs.utexas.edu/zjia/faas/types"
)

type funcHandlerFactory struct {
}

func (f *funcHandlerFactory) New(env types.Environment, funcName string) (types.FuncHandler, error) {
	//TODO
	funcName = strings.Replace(funcName, "0", "", -1)
	funcName = strings.Replace(funcName, "1", "", -1)
	funcName = strings.Replace(funcName, "2", "", -1)
	funcName = strings.Replace(funcName, "3", "", -1)
	funcName = strings.Replace(funcName, "4", "", -1)
	funcName = strings.Replace(funcName, "5", "", -1)
	funcName = strings.Replace(funcName, "6", "", -1)
	funcName = strings.Replace(funcName, "7", "", -1)
	funcName = strings.Replace(funcName, "8", "", -1)
	funcName = strings.Replace(funcName, "9", "", -1)
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
	case constants.FunctionAppendAndReadLoopAsync:
		return handlers.NewAppendReadLoopHandler(env, true), nil
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
