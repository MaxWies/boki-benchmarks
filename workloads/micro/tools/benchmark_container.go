package main

import (
	"faas-micro/client"
	"faas-micro/constants"
	"faas-micro/operations"
	"faas-micro/utils"
	"fmt"
	"log"
	"path"
)

func mergeSync(mergeFunction string, functionName string) {
	clientDirectory := path.Join(constants.BASE_PATH_SLOG_CLIENT_BENCHMARK, FLAGS_benchmark_type)
	engineDirectory := path.Join(constants.BASE_PATH_SLOG_ENGINE_BENCHMARK, FLAGS_benchmark_type) // created by engine(s)
	utils.CreateOutputDirectory(clientDirectory)

	mergeClient := client.NewSimpleClient(FLAGS_faas_gateway, &client.CallSync{})
	e := 0
	for e < FLAGS_engine_nodes {
		// merge at engine
		// we assume round robin
		mergeClient.SendRequest(mergeFunction, utils.JSONValue{
			"directory": engineDirectory,
			"function":  functionName,
		})
		e++
	}
	// merge results from engines
	mergedResponse := operations.Benchmark{}
	mergedEngineResults := 0
	for i, httpResult := range mergeClient.HttpResults {
		if httpResult.Err != nil || !httpResult.Success {
			log.Printf("[ERROR] Merge request failed. Response status code %d", httpResult.StatusCode)
			continue
		}
		mergeInput := httpResult.Result.(operations.Benchmark)
		// write per-engine result to file
		if err := (&mergeInput).WriteToFile(clientDirectory, fmt.Sprintf("engine-%d-%s", i, functionName)); err != nil {
			log.Printf("[ERROR] Merge responses of all engines not successful")
			return
		}
		if i == 0 {
			mergedResponse = mergeInput
			mergedEngineResults++
			continue
		}
		(&mergedResponse).Merge(&mergeInput)
		mergedEngineResults++
	}

	(&mergedResponse).Description = operations.Description{
		Benchmark:            FLAGS_benchmark_description,
		Throughput:           "[Op/s] Operations per second",
		Latency:              "[microsec] Operation latency",
		RecordSize:           FLAGS_record_length,
		SnapshotInterval:     FLAGS_snapshot_interval,
		ConcurrentClients:    FLAGS_concurrency_client,
		ConcurrentEngines:    mergedEngineResults,
		ConcurrentWorkers:    FLAGS_concurrency_worker,
		ConcurrentOperations: FLAGS_concurrency_operation,
		EngineNodes:          FLAGS_engine_nodes,
		UseTags:              FLAGS_use_tags,
	}

	// write all engines result to file
	if err := (&mergedResponse).WriteToFile(clientDirectory, fmt.Sprintf("engine-%s", functionName)); err != nil {
		log.Printf("[ERROR] Merge responses of all engines not successful")
	}
}

func containerLoop(functionName string, requestInputBuilder func() utils.JSONValue) {
	log.Printf("[INFO] Run loop function %s. Concurrency: %d. Duration: %d", functionName, FLAGS_concurrency_worker*FLAGS_concurrency_operation, FLAGS_duration)
	appendClient := client.NewSimpleClient(FLAGS_faas_gateway, &client.CallAsync{})
	c := 0
	for c < FLAGS_engine_nodes*FLAGS_concurrency_worker {
		appendClient.SendRequest(FLAGS_fn_prefix+functionName, requestInputBuilder())
		c++
	}
	success := 0
	for _, r := range appendClient.HttpResults {
		if r.Success {
			success++
		}
	}
	log.Printf("[INFO] %d successful results from %d total results.", success, len(appendClient.HttpResults))
}

func mergeContainerResults(functionName string) {
	mergeFunction := fmt.Sprintf("%s%s", FLAGS_fn_merge_prefix, constants.FunctionMergeResults)
	mergeSync(mergeFunction, functionName)
}
