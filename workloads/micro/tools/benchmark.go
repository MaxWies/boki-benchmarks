package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"path"
	"time"

	"faas-micro/client"
	"faas-micro/constants"
	"faas-micro/operations"
	"faas-micro/utils"

	"github.com/montanaflynn/stats"
)

var FLAGS_faas_gateway string
var FLAGS_fn_prefix string
var FLAGS_fn_merge_prefix string
var FLAGS_num_users int
var FLAGS_concurrency int
var FLAGS_duration int
var FLAGS_percentages string
var FLAGS_bodylen int
var FLAGS_rand_seed int
var FLAGS_benchmark_type string

var FLAGS_record_length int
var FLAGS_latency_bucket_lower int
var FLAGS_latency_bucket_upper int
var FLAGS_latency_bucket_granularity int
var FLAGS_latency_head_size int
var FLAGS_latency_tail_size int

var FLAGS_snapshot_interval int

var FLAGS_num_engines int

var FLAGS_read_times int

var FLAGS_logbooks int

var FLAGS_concurrency_operation int

func init() {
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
	flag.StringVar(&FLAGS_fn_prefix, "fn_prefix", "", "")
	flag.StringVar(&FLAGS_fn_merge_prefix, "fn_merge_prefix", "", "")
	flag.IntVar(&FLAGS_num_users, "num_users", 1000, "")
	flag.IntVar(&FLAGS_concurrency, "concurrency", 1, "")
	flag.IntVar(&FLAGS_rand_seed, "rand_seed", 23333, "")
	flag.StringVar(&FLAGS_benchmark_type, "benchmark_type", constants.BenchmarkAppend, "")

	flag.IntVar(&FLAGS_duration, "duration", 10, "")
	flag.IntVar(&FLAGS_snapshot_interval, "snapshot_interval", 5, "")

	flag.IntVar(&FLAGS_record_length, "record_length", 1024, "")
	flag.IntVar(&FLAGS_latency_bucket_lower, "latency_bucket_lower", 300, "")            //microsec
	flag.IntVar(&FLAGS_latency_bucket_upper, "latency_bucket_upper", 10000, "")          //microsec
	flag.IntVar(&FLAGS_latency_bucket_granularity, "latency_bucket_granularity", 10, "") //microsec
	flag.IntVar(&FLAGS_latency_head_size, "latency_head_size", 20, "")
	flag.IntVar(&FLAGS_latency_tail_size, "latency_tail_size", 20, "")
	flag.IntVar(&FLAGS_num_engines, "num_engines", 1, "")
	flag.IntVar(&FLAGS_read_times, "read_times", 1, "")

	flag.IntVar(&FLAGS_logbooks, "logbooks", 1, "")

	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_client", 1, "") //todo
	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_operation", 1, "")

	rand.Seed(int64(FLAGS_rand_seed))
}

func buildAppendRequest() utils.JSONValue {
	return utils.JSONValue{}
}

func buildMicrobenchmarkRequest() utils.JSONValue {
	record := utils.CreateRecord(FLAGS_record_length)
	fmt.Printf("Length of record is %d", len(record))
	return utils.JSONValue{
		"record":                     record,
		"read_times":                 FLAGS_read_times,
		"loop_duration":              FLAGS_duration,
		"snapshot_interval":          FLAGS_snapshot_interval,
		"latency_bucket_lower":       FLAGS_latency_bucket_lower,
		"latency_bucket_upper":       FLAGS_latency_bucket_upper,
		"latency_bucket_granularity": FLAGS_latency_bucket_granularity,
		"latency_head_size":          FLAGS_latency_head_size,
		"latency_tail_size":          FLAGS_latency_tail_size,
		"benchmark_type":             FLAGS_benchmark_type,
		"concurrent_operations":      FLAGS_concurrency_operation,
	}
}

func buildReadRequest() utils.JSONValue {
	return utils.JSONValue{}
}

// func buildAppendReadLoopRequest() utils.JSONValue {
// 	record := utils.CreateRecord(FLAGS_record_length)
// 	fmt.Printf("Length of record is %d", len(record))
// 	return utils.JSONValue{
// 		"record":                     record,
// 		"read_times":                 FLAGS_read_times,
// 		"loop_duration":              FLAGS_duration,
// 		"latency_bucket_lower":       FLAGS_latency_bucket_lower,
// 		"latency_bucket_upper":       FLAGS_latency_bucket_upper,
// 		"latency_bucket_granularity": FLAGS_latency_bucket_granularity,
// 		"latency_head_size":          FLAGS_latency_head_size,
// 		"latency_tail_size":          FLAGS_latency_tail_size,
// 		"benchmark_type":             FLAGS_benchmark_type,
// 	}
// }

func printFnResult(fnName string, duration time.Duration, results []*utils.FaasCall) {
	total := 0
	succeeded := 0
	latencies := make([]float64, 0, 128)
	for _, result := range results {
		if result.FnName == FLAGS_fn_prefix+fnName {
			total++
			if result.Result.Success {
				succeeded++
			}
			if result.Result.StatusCode == 200 {
				d := result.Result.Duration
				latencies = append(latencies, float64(d.Microseconds()))
			}
		}
	}
	if total == 0 {
		return
	}
	failed := total - succeeded
	fmt.Printf("[%s]\n", fnName)
	fmt.Printf("Throughput: %.1f requests per sec\n", float64(total)/duration.Seconds())
	if failed > 0 {
		ratio := float64(failed) / float64(total)
		fmt.Printf("Failed requests: %d (%.2f%%)\n", failed, ratio*100.0)
	}
	if len(latencies) > 0 {
		median, _ := stats.Median(latencies)
		p99, _ := stats.Percentile(latencies, 99.0)
		fmt.Printf("Latency: median = %.3fms, tail (p99) = %.3fms\n", median/1000.0, p99/1000.0)
	}
}

func clientBenchmark(functionName string, functionBuilder func() utils.JSONValue) {
	client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency)
	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(FLAGS_duration)*time.Second {
			break
		}
		client.AddJsonFnCall(FLAGS_fn_prefix+functionName, functionBuilder())
	}
	results := client.WaitForResults()
	elapsed := time.Since(startTime)
	fmt.Printf("Benchmark runs for %v, %.1f request per sec\n", elapsed, float64(len(results))/elapsed.Seconds())
	printFnResult(functionName, elapsed, results)
}

func clientLoopBenchmark(functionName string, requestInputBuilder func() utils.JSONValue) {
	log.Printf("[INFO] Run loop functions. Function mode: %s. Concurrency: %d. Duration: %d", FLAGS_benchmark_type, FLAGS_concurrency, FLAGS_duration)
	c := 0
	client := client.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency, &client.CallSync{})
	for c < FLAGS_concurrency {
		client.AddJsonFnCall(FLAGS_fn_prefix+functionName, requestInputBuilder())
		c++
	}
	faasCalls := client.WaitForHttpResults()
	for _, faasCall := range faasCalls {
		if faasCall.HttpResult.Success {
			appendLoopOutput := faasCall.HttpResult.Result.(operations.Benchmark)
			fmt.Printf("Calls Total: %d", appendLoopOutput.Calls)
			fmt.Printf("Calls Success: %d", appendLoopOutput.Success)
			fmt.Printf("Calls Failure: %d", appendLoopOutput.Calls-appendLoopOutput.Success)
			fmt.Printf("Throughput: %.2f [Op/s] using %d bytes records", appendLoopOutput.Throughput, FLAGS_record_length)
		}
	}
}

func mergeSync(mergeFunction string, functionName string) {
	clientDirectory := path.Join(constants.BASE_PATH_CLIENT_BOKI_BENCHMARK, FLAGS_benchmark_type)
	engineDirectory := path.Join(constants.BASE_PATH_ENGINE_BOKI_BENCHMARK, FLAGS_benchmark_type) // created by engine(s)
	utils.CreateOutputDirectory(clientDirectory)

	mergeClient := client.NewSimpleClient(FLAGS_faas_gateway, &client.CallSync{})
	e := 0
	for e < FLAGS_num_engines {
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

	(&mergedResponse).Description.Engines = mergedEngineResults

	// write all engines result to file
	if err := (&mergedResponse).WriteToFile(clientDirectory, fmt.Sprintf("engine-%s", functionName)); err != nil {
		log.Printf("[ERROR] Merge responses of all engines not successful")
	}
}

func clientLoopAsyncBenchmark(functionName string, requestInputBuilder func() utils.JSONValue) {
	log.Printf("[INFO] Run loop function %s. Concurrency: %d. Duration: %d", functionName, FLAGS_concurrency, FLAGS_duration)
	appendClient := client.NewSimpleClient(FLAGS_faas_gateway, &client.CallAsync{})
	c := 0
	for c < FLAGS_concurrency {
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
	time.Sleep(time.Duration(FLAGS_duration*2) * time.Second)

	mergeFunction := fmt.Sprintf("%s%s", FLAGS_fn_merge_prefix, constants.FunctionMergeResults)
	mergeSync(mergeFunction, functionName)
}

func logbookVirtualizationBenchmark(functionName string, requestInputBuilder func() utils.JSONValue) {
	log.Printf("[INFO] Run logbook virtualization benchmark using function %s. Logbooks: %d. Duration: %d", functionName, FLAGS_logbooks, FLAGS_duration)
	client := client.NewSimpleClient(FLAGS_faas_gateway, &client.CallAsync{})
	c := 1
	for c <= FLAGS_logbooks {
		functionName := fmt.Sprintf("%s%s%d", FLAGS_fn_prefix, functionName, c)
		client.SendRequest(functionName, requestInputBuilder())
		c++
	}
	success := 0
	for _, r := range client.HttpResults {
		if r.Success {
			success++
		}
	}
	log.Printf("[INFO] %d successful results from %d total results.", success, len(client.HttpResults))
	time.Sleep(time.Duration(FLAGS_duration*2) * time.Second)

	mergeFunction := fmt.Sprintf("%s%s%d", FLAGS_fn_merge_prefix, constants.FunctionMergeResults, c)
	mergeSync(mergeFunction, functionName)
}

func main() {
	flag.Parse()
	switch FLAGS_benchmark_type {
	case constants.BenchmarkAppend:
		builder := buildAppendRequest
		clientBenchmark(constants.FunctionAppend, builder)
	// case constants.Read:
	// 	builder := buildAppendToLogRequest
	// 	clientBenchmark(constants.Read, builder)
	// case constants.AppendLoop:
	// 	builder := buildAppendToLogLoopRequest
	// 	clientLoopBenchmark(constants.AppendLoop, builder)
	case constants.BenchmarkAppendThroughput:
		builder := buildMicrobenchmarkRequest
		clientLoopAsyncBenchmark(constants.FunctionAppendLoopAsync, builder)
	case constants.BenchmarkAppendAndReadThroughput:
		builder := buildMicrobenchmarkRequest
		clientLoopAsyncBenchmark(constants.FunctionAppendAndReadLoopAsync, builder)
	case constants.BenchmarkLogbookVirtualization:
		builder := buildMicrobenchmarkRequest
		logbookVirtualizationBenchmark(constants.FunctionAppendLoopAsync, builder)
	default:
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
}
