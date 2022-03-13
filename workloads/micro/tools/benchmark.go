package main

import (
	"flag"
	"fmt"
	"math/rand"

	"faas-micro/constants"
	"faas-micro/utils"
)

var FLAGS_faas_gateway string
var FLAGS_fn_prefix string
var FLAGS_fn_merge_prefix string
var FLAGS_num_users int
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

var FLAGS_concurrency_client int
var FLAGS_concurrency_worker int
var FLAGS_concurrency_operation int

func init() {
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
	flag.StringVar(&FLAGS_fn_prefix, "fn_prefix", "", "")
	flag.StringVar(&FLAGS_fn_merge_prefix, "fn_merge_prefix", "", "")
	flag.IntVar(&FLAGS_num_users, "num_users", 1000, "")
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

	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_client", 1, "")
	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_worker", 1, "")
	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_operation", 1, "")

	rand.Seed(int64(FLAGS_rand_seed))
}

func buildAppendRequest() utils.JSONValue {
	return utils.JSONValue{}
}

func buildMicrobenchmarkRequest() utils.JSONValue {
	record := utils.CreateRecord(FLAGS_record_length)
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
		workerLoopBenchmark(constants.FunctionAppendLoopAsync, builder)
	case constants.BenchmarkAppendAndReadThroughput:
		builder := buildMicrobenchmarkRequest
		workerLoopBenchmark(constants.FunctionAppendAndReadLoopAsync, builder)
	case constants.BenchmarkLogbookVirtualization:
		builder := buildMicrobenchmarkRequest
		logbookVirtualizationBenchmark(constants.FunctionAppendLoopAsync, builder)
	default:
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
}
